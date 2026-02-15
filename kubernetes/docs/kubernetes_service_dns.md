# Kubernetes Service と DNS の仕組み

> 調査日: 2026-02-14

本ドキュメントは、Kubernetes が既定で提供する **Service** と **DNS** の仕組みについて、クラスター内部のネットワーキングの観点から解説します。AKS 固有の話題ではなく、Kubernetes 本体のアーキテクチャに基づいています。

---

## 全体像

Kubernetes クラスターには、Pod 間の通信を支える 2 つの基盤メカニズムが組み込まれています。

```mermaid
graph TB
    subgraph ControlPlane["コントロールプレーン"]
        API["kube-apiserver<br/>--service-cluster-ip-range で<br/>Service CIDR を定義"]
    end

    subgraph DataPlane["各ノード上のデータプレーン"]
        KP["kube-proxy<br/>iptables / IPVS ルールを管理"]
    end

    subgraph ClusterDNS["クラスター DNS"]
        CoreDNS["CoreDNS Pod<br/>サービス名 → ClusterIP を解決"]
    end

    API -- "Service の作成・変更を通知" --> KP
    API -- "Service の作成・変更を通知" --> CoreDNS
    KP -- "ClusterIP → Pod IP への<br/>パケット転送ルールを設定" --> Nodes["ノードの netfilter"]
    CoreDNS -- "DNS レコードを提供" --> Pods["全 Pod"]
```

| 基盤                   | 役割                                     | 担当コンポーネント          |
| ---------------------- | ---------------------------------------- | --------------------------- |
| **Service（仮想 IP）** | Pod 群に安定したエンドポイントを提供する | kube-apiserver + kube-proxy |
| **DNS（名前解決）**    | サービス名を仮想 IP に変換する           | CoreDNS（旧 kube-dns）      |

---

## Service の仕組み

### なぜ Service が必要か

Pod は一時的な存在です。スケーリングやデプロイのたびに IP が変わります。Service は Pod 群の前に「安定した仮想 IP（ClusterIP）」を置き、クライアントが個々の Pod の IP を意識せずに通信できる仕組みです。

```mermaid
graph LR
    Client["クライアント Pod"]

    subgraph Service["Service: my-api<br/>ClusterIP: 10.96.0.50"]
        direction TB
    end

    subgraph Endpoints["Endpoints（Pod 群）"]
        Pod1["Pod A<br/>10.244.1.10"]
        Pod2["Pod B<br/>10.244.2.20"]
        Pod3["Pod C<br/>10.244.3.30"]
    end

    Client -- "宛先: 10.96.0.50:80" --> Service
    Service --> Pod1
    Service --> Pod2
    Service --> Pod3
```

### ClusterIP の割り当て

kube-apiserver の起動パラメータ `--service-cluster-ip-range`（AKS では `service_cidr`）で定義された CIDR から、Service ごとにユニークな IP が割り当てられます。

```mermaid
graph TB
    subgraph CIDR["service-cluster-ip-range: 10.96.0.0/16"]
        Reserved["10.96.0.1<br/>kubernetes.default.svc 用<br/>（予約済み）"]
        DNS["10.96.0.10<br/>kube-dns Service 用<br/>（= dns_service_ip）"]
        Svc1["10.96.0.50<br/>my-api Service"]
        Svc2["10.96.1.100<br/>my-web Service"]
        Free["10.96.2.0 〜<br/>未割り当て"]
    end

    Reserved -.- DNS -.- Svc1 -.- Svc2 -.- Free
```

**重要な制約:**

- ClusterIP はクラスター内部のみで有効です。VNet 上にはルーティングされません
- Service CIDR の最初の IP（`10.96.0.1`）は `kubernetes.default.svc.cluster.local` に自動予約されます
- `dns_service_ip`（既定: `.10`）は CoreDNS Service の ClusterIP です

### kube-proxy によるパケット転送

ClusterIP は「仮想的」な IP であり、どのネットワークインターフェースにも割り当てられていません。実際のパケット転送は、各ノード上の **kube-proxy** が設定する **iptables / IPVS ルール**によって実現されます。

```mermaid
sequenceDiagram
    participant App as クライアント Pod
    participant IPT as iptables<br/>(kube-proxy が設定)
    participant Pod1 as Pod A<br/>10.244.1.10
    participant Pod2 as Pod B<br/>10.244.2.20
    participant Pod3 as Pod C<br/>10.244.3.30

    Note over IPT: kube-proxy が API Server を監視し<br/>Service/Endpoints の変更を検知して<br/>iptables ルールを更新

    App->>IPT: パケット送信<br/>宛先: 10.96.0.50:80
    Note over IPT: KUBE-SERVICES チェーンで<br/>ClusterIP 10.96.0.50 にマッチ
    Note over IPT: DNAT で宛先を Pod IP に書き換え<br/>（確率ベースのランダム選択）

    alt 1/3 の確率
        IPT->>Pod1: DNAT → 10.244.1.10:9376
    else 1/3 の確率
        IPT->>Pod2: DNAT → 10.244.2.20:9376
    else 1/3 の確率
        IPT->>Pod3: DNAT → 10.244.3.30:9376
    end
```

実際の iptables ルールの例（Kubernetes 公式ドキュメントより）:

```shell
# ClusterIP 10.0.1.175:80 へのトラフィックを KUBE-SVC チェーンに転送
-A KUBE-SERVICES -d 10.0.1.175/32 -p tcp --dport 80 -j KUBE-SVC-NWV5X2332I4OT4T3

# 3 つの Pod に均等に分散（確率ベースのランダム選択）
-A KUBE-SVC-... -m statistic --mode random --probability 0.33333 -j KUBE-SEP-...(Pod A)
-A KUBE-SVC-... -m statistic --mode random --probability 0.50000 -j KUBE-SEP-...(Pod B)
-A KUBE-SVC-... -j KUBE-SEP-...(Pod C)

# 各 Pod への DNAT（宛先 NAT）ルール
-A KUBE-SEP-... -p tcp -j DNAT --to-destination 10.244.3.6:9376
```

### kube-proxy のモード

| モード               | 仕組み                              | 特徴                               |
| -------------------- | ----------------------------------- | ---------------------------------- |
| **iptables**（既定） | netfilter の iptables ルールで DNAT | Service 数が増えるとルール数が増大 |
| **IPVS**             | Linux カーネルの IP Virtual Server  | 大規模クラスターで高パフォーマンス |

---

## DNS の仕組み

### CoreDNS の役割

CoreDNS は kube-system namespace で動作する Pod で、Kubernetes API を監視し、Service が作成されるたびに DNS レコードを自動生成します。

```mermaid
graph TB
    subgraph KubeSystem["kube-system namespace"]
        CoreDNSPod["CoreDNS Pod<br/>Pod IP: 10.244.0.12"]
        KubeDNSSvc["kube-dns Service<br/>ClusterIP: 10.96.0.10<br/>（= dns_service_ip）"]
    end

    subgraph API["kube-apiserver"]
        SvcWatch["Service/Endpoints の<br/>変更を Watch"]
    end

    API -- "新しい Service を検知" --> CoreDNSPod
    CoreDNSPod -- "DNS レコードを生成<br/>my-api.default.svc.cluster.local<br/>→ 10.96.0.50" --> CoreDNSPod

    KubeDNSSvc -- "kube-proxy 経由で<br/>Pod IP に転送" --> CoreDNSPod
```

**CoreDNS 自体も Service + Pod の構成です:**

- CoreDNS **Pod** は `pod_cidr` から IP を取得します（例: `10.244.0.12`）
- CoreDNS **Service**（`kube-dns`）は `service_cidr` から ClusterIP を取得します（例: `10.96.0.10`）
- Pod が DNS クエリを送る先は Service の ClusterIP で、kube-proxy が CoreDNS Pod に転送します

### Pod の DNS 設定

Kubernetes は Pod 作成時に `/etc/resolv.conf` を自動生成します。

```text
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

| 設定         | 値                           | 説明                                                    |
| ------------ | ---------------------------- | ------------------------------------------------------- |
| `nameserver` | `10.96.0.10`                 | CoreDNS Service の ClusterIP（= `dns_service_ip`）      |
| `search`     | `<ns>.svc.cluster.local ...` | 短縮名を展開する検索ドメインリスト                      |
| `ndots`      | `5`                          | ドットが 5 個未満の名前は search ドメインを付加して検索 |

### DNS 名前解決フロー

Pod 内のアプリケーションが `my-api` というサービス名で通信する場合の完全なフローです。

```mermaid
sequenceDiagram
    participant App as アプリケーション Pod<br/>(default namespace)
    participant Resolv as /etc/resolv.conf
    participant KP1 as kube-proxy<br/>(iptables)
    participant DNS as CoreDNS Pod<br/>10.244.0.12
    participant KP2 as kube-proxy<br/>(iptables)
    participant Target as my-api Pod<br/>10.244.2.20

    Note over App: "my-api" に HTTP リクエストを送信

    App->>Resolv: DNS クエリ: "my-api"
    Note over Resolv: ndots:5 のため search ドメインを付加<br/>"my-api.default.svc.cluster.local"

    Resolv->>KP1: DNS クエリ<br/>宛先: 10.96.0.10:53
    KP1->>DNS: DNAT<br/>10.96.0.10 → 10.244.0.12

    Note over DNS: Kubernetes API から取得済みの<br/>Service レコードを検索

    DNS-->>App: 応答: 10.96.0.50<br/>(my-api Service の ClusterIP)

    App->>KP2: HTTP リクエスト<br/>宛先: 10.96.0.50:80
    KP2->>Target: DNAT<br/>10.96.0.50 → 10.244.2.20:8080

    Target-->>App: HTTP レスポンス
```

### DNS レコードの形式

CoreDNS は Service の種類に応じて以下の DNS レコードを自動生成します。

```mermaid
graph TB
    subgraph Records["CoreDNS が生成する DNS レコード"]
        A["A/AAAA レコード<br/>my-api.default.svc.cluster.local<br/>→ 10.96.0.50（ClusterIP）"]
        SRV["SRV レコード<br/>_http._tcp.my-api.default.svc.cluster.local<br/>→ ポート番号 + ホスト名"]
        Headless["Headless Service の場合<br/>my-db.default.svc.cluster.local<br/>→ 10.244.1.10, 10.244.2.20<br/>（Pod IP を直接返す）"]
    end
```

| Service タイプ                | DNS レコードの返す値    | 用途                                    |
| ----------------------------- | ----------------------- | --------------------------------------- |
| 通常の ClusterIP              | Service の ClusterIP    | ロードバランシングが必要な場合          |
| Headless（`clusterIP: None`） | 各 Pod の IP を直接返す | StatefulSet 等で Pod を直接指定する場合 |

### DNS 名の省略規則

`search` ドメインにより、同一 namespace 内では短縮名が使用できます。

| Pod の namespace | 宛先 Service    | 指定する名前      | 展開結果                            |
| ---------------- | --------------- | ----------------- | ----------------------------------- |
| default          | default/my-api  | `my-api`          | `my-api.default.svc.cluster.local`  |
| default          | other-ns/my-api | `my-api.other-ns` | `my-api.other-ns.svc.cluster.local` |
| 任意             | 任意            | FQDN 指定         | `my-api.default.svc.cluster.local.` |

---

## 既定で存在する Service

Kubernetes クラスターは起動時に以下の Service を自動作成します。

```mermaid
graph TB
    subgraph DefaultNS["default namespace"]
        K8sSvc["kubernetes Service<br/>ClusterIP: 10.96.0.1<br/>→ kube-apiserver への内部アクセス"]
    end

    subgraph KubeSystemNS["kube-system namespace"]
        DNSSvc["kube-dns Service<br/>ClusterIP: 10.96.0.10（= dns_service_ip）<br/>→ CoreDNS Pod への DNS クエリ転送"]
    end

    Pod["任意の Pod"] -- "kubectl API 呼び出し<br/>kubernetes.default.svc:443" --> K8sSvc
    Pod -- "DNS クエリ<br/>kube-dns.kube-system.svc:53" --> DNSSvc
```

| Service      | namespace   | ClusterIP                            | 役割                                                       |
| ------------ | ----------- | ------------------------------------ | ---------------------------------------------------------- |
| `kubernetes` | default     | CIDR の最初の IP（例: `10.96.0.1`）  | Pod から kube-apiserver にアクセスするためのエンドポイント |
| `kube-dns`   | kube-system | `dns_service_ip`（例: `10.96.0.10`） | 全 Pod の `/etc/resolv.conf` に設定される DNS サーバー     |

---

## CoreDNS の構成

CoreDNS は ConfigMap（`kube-system/coredns`）で構成されます。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health { lameduck 5s }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
            ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
```

| プラグイン    | 役割                                                            |
| ------------- | --------------------------------------------------------------- |
| `kubernetes`  | `cluster.local` ドメインの名前解決を Kubernetes API から取得    |
| `forward`     | クラスター外のドメイン（例: `google.com`）をノードの DNS に転送 |
| `cache`       | DNS レスポンスを 30 秒キャッシュ                                |
| `loadbalance` | A レコードの応答順序をラウンドロビンでシャッフル                |

---

## まとめ: パケットが Pod に届くまでの全経路

```mermaid
graph TB
    App["アプリ Pod<br/>curl http://my-api/hello"]

    subgraph Step1["1. DNS 解決"]
        Resolv["/etc/resolv.conf<br/>nameserver: 10.96.0.10"]
        IPT1["iptables DNAT<br/>10.96.0.10 → 10.244.0.12"]
        CoreDNS["CoreDNS Pod<br/>10.244.0.12"]
    end

    subgraph Step2["2. ClusterIP への通信"]
        SvcIP["Service ClusterIP<br/>10.96.0.50"]
        IPT2["iptables DNAT<br/>10.96.0.50 → 10.244.2.20<br/>（ランダム選択）"]
    end

    subgraph Step3["3. Pod 間通信"]
        TargetPod["my-api Pod<br/>10.244.2.20"]
    end

    App --> Resolv
    Resolv --> IPT1
    IPT1 --> CoreDNS
    CoreDNS -- "応答: 10.96.0.50" --> App
    App --> SvcIP
    SvcIP --> IPT2
    IPT2 --> TargetPod
    TargetPod -- "レスポンス" --> App
```

1. **DNS 解決**: アプリが `my-api` を名前解決 → CoreDNS が ClusterIP `10.96.0.50` を返す
2. **ClusterIP 転送**: kube-proxy の iptables ルールが ClusterIP を Pod IP に DNAT
3. **Pod 間通信**: パケットが実際の Pod に到達し、レスポンスが返る

**Service と DNS は独立した仕組みですが、組み合わせることで「サービス名だけで Pod 間通信ができる」という Kubernetes の中核機能を実現しています。**

---

## 参考リンク

### Kubernetes 公式ドキュメント

- [Service](https://kubernetes.io/docs/concepts/services-networking/service/) — Service の概念全体
- [Virtual IPs and Service Proxies](https://kubernetes.io/docs/reference/networking/virtual-ips/) — kube-proxy による仮想 IP の実装
- [Service ClusterIP allocation](https://kubernetes.io/docs/concepts/services-networking/cluster-ip-allocation/) — ClusterIP の割り当て方式
- [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) — CoreDNS によるサービスディスカバリ
- [Customizing DNS Service](https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/) — CoreDNS の構成カスタマイズ

### Microsoft Learn（AKS）

- [AKS ネットワーク概念](https://learn.microsoft.com/en-us/azure/aks/concepts-network) — AKS でのネットワーク全体像
- [AKS IP アドレス計画](https://learn.microsoft.com/en-us/azure/aks/concepts-network-ip-address-planning) — Service CIDR のサイジング
- [AKS の DNS 概念](https://learn.microsoft.com/en-us/azure/aks/dns-concepts) — AKS での CoreDNS 動作
- [AKS の Service 概念](https://learn.microsoft.com/en-us/azure/aks/concepts-network-services) — AKS での Service タイプ
