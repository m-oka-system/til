# Kubernetes サービスタイプの違い

このドキュメントでは、Kubernetes のサービスタイプの違いを Mermaid 図を用いて視覚的に説明します。

## 目次

1. [サービスタイプの概要](#サービスタイプの概要)
2. [ClusterIP（通常型）](#1-clusterip通常型)
3. [Headless Service（clusterIP: None）](#2-headless-serviceclusterip-none)
4. [NodePort](#3-nodeport)
5. [LoadBalancer](#4-loadbalancer)
6. [ExternalName](#5-externalname)
7. [比較表](#比較表)

---

## サービスタイプの概要

Kubernetes の Service は、Pod へのアクセスを提供するための抽象化レイヤーです。以下の 5 つのタイプがあります。

```mermaid
graph TB
    subgraph "Kubernetes Service Types"
        A[Service] --> B[ClusterIP]
        A --> C[Headless Service]
        A --> D[NodePort]
        A --> E[LoadBalancer]
        A --> F[ExternalName]
    end
```

---

## 1. ClusterIP（通常型）

**説明**: クラスタ内部でのみアクセス可能な仮想 IP アドレスを提供します。

### アーキテクチャ図

```mermaid
graph TB
    subgraph "Kubernetes Cluster"
        subgraph "Node 1"
            Pod1[Pod: app-1<br/>IP: 10.244.1.10]
            Pod2[Pod: app-2<br/>IP: 10.244.1.11]
        end

        subgraph "Node 2"
            Pod3[Pod: app-3<br/>IP: 10.244.2.10]
        end

        Service[Service: ClusterIP<br/>IP: 10.96.0.100<br/>Port: 80]

        Client[クラスタ内のクライアント]

        Service -->|ロードバランシング| Pod1
        Service -->|ロードバランシング| Pod2
        Service -->|ロードバランシング| Pod3

        Client -->|"10.96.0.100:80"| Service
    end

    External[外部クライアント] -->|"アクセス不可"| Service
```

### データフロー

```mermaid
sequenceDiagram
    participant Client as クラスタ内クライアント
    participant Service as Service (ClusterIP)
    participant Pod1 as Pod 1
    participant Pod2 as Pod 2

    Client->>Service: リクエスト (10.96.0.100:80)
    Service->>Service: ロードバランシング決定
    alt ラウンドロビン
        Service->>Pod1: リクエスト転送
        Pod1->>Service: レスポンス
    else 次のリクエスト
        Service->>Pod2: リクエスト転送
        Pod2->>Service: レスポンス
    end
    Service->>Client: レスポンス返却
```

### 特徴

- ✅ クラスタ内部からのみアクセス可能
- ✅ 仮想 IP アドレス（例: 10.96.0.100）が自動割り当て
- ✅ 複数の Pod にロードバランシング
- ❌ クラスタ外部からはアクセス不可

### 使用例

```yaml
spec:
  type: ClusterIP # デフォルト（省略可能）
  selector:
    app: sample-app
  ports:
    - port: 80
      targetPort: 8080
```

---

## 2. Headless Service（clusterIP: None）

**説明**: 仮想 IP を割り当てず、各 Pod の IP アドレスを直接返すサービスです。

### アーキテクチャ図

```mermaid
graph TB
    subgraph "Kubernetes Cluster"
        subgraph "StatefulSet: postgres"
            Pod0[Pod: postgres-0<br/>IP: 10.244.1.20]
            Pod1[Pod: postgres-1<br/>IP: 10.244.1.21]
            Pod2[Pod: postgres-2<br/>IP: 10.244.1.22]
        end

        Service[Service: Headless<br/>clusterIP: None<br/>DNS: postgres-service]

        Client[クラスタ内のクライアント]

        Client -->|"DNS クエリ"| Service
        Service -->|"直接IP返却"| Pod0
        Service -->|"直接IP返却"| Pod1
        Service -->|"直接IP返却"| Pod2

        Client -->|"10.244.1.20:5432"| Pod0
        Client -->|"10.244.1.21:5432"| Pod1
        Client -->|"10.244.1.22:5432"| Pod2
    end
```

### DNS 解決の流れ

```mermaid
sequenceDiagram
    participant Client as クライアント
    participant DNS as Kubernetes DNS
    participant Service as Headless Service
    participant Pod0 as postgres-0
    participant Pod1 as postgres-1

    Client->>DNS: postgres-service.namespace.svc.cluster.local を解決
    DNS->>Service: サービス情報を取得
    Service->>DNS: Pod IPリストを返却
    Note over Service: 仮想IPなし<br/>各PodのIPを直接返す
    DNS->>Client: [10.244.1.20, 10.244.1.21, 10.244.1.22]

    Client->>Pod0: 直接接続 (10.244.1.20:5432)
    Client->>Pod1: 直接接続 (10.244.1.21:5432)
```

### 特徴

- ✅ 各 Pod の IP アドレスを直接取得可能
- ✅ StatefulSet と組み合わせて使用
- ✅ データベースのレプリケーションに適している
- ❌ 仮想 IP アドレスなし（ロードバランシングなし）

### 使用例

```yaml
spec:
  clusterIP: None # Headless Service
  selector:
    app: postgres
  ports:
    - port: 5432
      name: postgres
```

---

## 3. NodePort

**説明**: クラスタ内のすべてのノードの同じポート番号で外部からアクセスできるようにします。

**なぜこの仕組みなのか**: NodePort タイプの Service を作成すると、各ノードで実行されている kube-proxy が指定されたポート（30000-32767 の範囲）でリッスンします。外部クライアントは各ノードの IP アドレスと NodePort 番号を使って直接アクセスし、kube-proxy がそのトラフィックを Service の ClusterIP に転送します。これにより、どのノードにアクセスしても同じ Service に到達できます。

**注意**: 以下の図は minikube 環境（1 ノード構成）を想定しています。

### アーキテクチャ図

```mermaid
graph TB
    subgraph "外部ネットワーク（ローカル環境）"
        External[外部クライアント<br/>localhost または minikube IP]
    end

    subgraph "Kubernetes Cluster (minikube)"
        Service[Service: NodePort<br/>ClusterIP: 10.96.0.100<br/>NodePort: 30080]

        subgraph "Node (minikube)"
            KubeProxy[Kube-Proxy<br/>NodePort: 30080]

            subgraph "Pod コンテナ"
                Pod1[Pod: app-1<br/>IP: 10.244.0.10]
                Pod2[Pod: app-2<br/>IP: 10.244.0.11]
            end
        end

        External -->|"minikube IP:30080<br/>または localhost:30080"| KubeProxy
        KubeProxy -->|"ClusterIPに転送"| Service
        Service -->|ロードバランシング| Pod1
        Service -->|ロードバランシング| Pod2
    end
```

### データフロー（minikube 環境）

```mermaid
sequenceDiagram
    participant Client as 外部クライアント<br/>(localhost または minikube IP)
    participant KubeProxy as Kube-Proxy<br/>(minikube Node)
    participant Service as Service (ClusterIP)
    participant Pod as Pod

    Client->>KubeProxy: リクエスト (minikube IP:30080)
    Note over KubeProxy: NodePortでリッスン<br/>ポート30080で受信
    KubeProxy->>Service: ClusterIPに転送 (10.96.0.100:80)
    Service->>Service: ロードバランシング決定
    Service->>Pod: リクエスト転送
    Pod->>Service: レスポンス
    Service->>KubeProxy: レスポンス返却
    KubeProxy->>Client: レスポンス返却
```

### 特徴

- ✅ クラスタ外部からアクセス可能
- ✅ すべてのノードの同じポートでアクセス可能（複数ノード環境の場合）
- ✅ ポート番号: 30000-32767（自動または手動指定）
- ✅ minikube 環境では `minikube ip` で取得できる IP アドレスと NodePort 番号でアクセス可能
- ⚠️ 本番環境では通常 LoadBalancer や Ingress を使用

### 使用例

```yaml
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 8080
      nodePort: 30080 # オプション（省略時は自動割り当て）
```

---

## 4. LoadBalancer

**説明**: クラウドプロバイダーのロードバランサーを自動的に作成します。

### アーキテクチャ図

```mermaid
graph TB
    subgraph "インターネット"
        Internet[インターネットユーザー]
    end

    subgraph "クラウドプロバイダー (AWS/GCP/Azure)"
        LB[ロードバランサー<br/>IP: 203.0.113.10]
    end

    subgraph "Kubernetes Cluster"
        subgraph "Node 1"
            Pod1[Pod: app-1]
        end

        subgraph "Node 2"
            Pod2[Pod: app-2]
        end

        subgraph "Node 3"
            Pod3[Pod: app-3]
        end

        Service[Service: LoadBalancer<br/>External IP: 203.0.113.10]

        Service -->|ロードバランシング| Pod1
        Service -->|ロードバランシング| Pod2
        Service -->|ロードバランシング| Pod3
    end

    Internet -->|"203.0.113.10:80"| LB
    LB -->|転送| Service
```

### データフロー

```mermaid
sequenceDiagram
    participant User as インターネットユーザー
    participant LB as クラウドロードバランサー
    participant Service as LoadBalancer Service
    participant Pod as Pod

    User->>LB: リクエスト (203.0.113.10:80)
    LB->>Service: リクエスト転送
    Service->>Service: ロードバランシング
    Service->>Pod: リクエスト転送
    Pod->>Service: レスポンス
    Service->>LB: レスポンス返却
    LB->>User: レスポンス返却
```

### 特徴

- ✅ クラスタ外部から安定した IP アドレスでアクセス可能
- ✅ クラウドプロバイダーのロードバランサー機能を利用
- ✅ 本番環境に適している
- ⚠️ クラウドプロバイダーが必要（ローカル環境では動作しない）
- ⚠️ 追加コストが発生する場合がある

### 使用例

```yaml
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
```

---

## 5. ExternalName

**説明**: クラスタ外部のサービスを参照するための DNS エイリアスを提供します。

### アーキテクチャ図

```mermaid
graph TB
    subgraph "Kubernetes Cluster"
        Pod[Pod: アプリケーション]
        Service[Service: ExternalName<br/>externalName: db.example.com]
        DNS[Kubernetes DNS]
    end

    subgraph "外部ネットワーク"
        ExternalDB[外部データベース<br/>db.example.com<br/>IP: 203.0.113.50]
    end

    Pod -->|"DNS クエリ"| DNS
    DNS -->|"CNAME レコード返却"| Service
    Service -->|"外部DNS解決"| ExternalDB
    Pod -->|"直接接続"| ExternalDB
```

### DNS 解決の流れ

```mermaid
sequenceDiagram
    participant Pod as Pod
    participant K8sDNS as Kubernetes DNS
    participant Service as ExternalName Service
    participant ExtDNS as 外部DNS
    participant ExtDB as 外部データベース

    Pod->>K8sDNS: internal-service.namespace.svc.cluster.local を解決
    K8sDNS->>Service: サービス情報を取得
    Service->>K8sDNS: CNAME: db.example.com を返却
    K8sDNS->>Pod: CNAME: db.example.com

    Pod->>ExtDNS: db.example.com を解決
    ExtDNS->>Pod: IP: 203.0.113.50

    Pod->>ExtDB: 直接接続 (203.0.113.50:5432)
```

### 特徴

- ✅ クラスタ外部のサービスを簡単に参照可能
- ✅ DNS エイリアスとして機能
- ✅ 実際のトラフィックはクラスタ外に転送
- ❌ プロキシ機能なし（単純な DNS エイリアス）

### 使用例

```yaml
spec:
  type: ExternalName
  externalName: db.example.com
```

---

## 比較表

| タイプ           | クラスタ内部アクセス | クラスタ外部アクセス | 仮想 IP | 主な用途                  | コスト |
| ---------------- | -------------------- | -------------------- | ------- | ------------------------- | ------ |
| **ClusterIP**    | ✅                   | ❌                   | ✅      | 内部通信（デフォルト）    | 無料   |
| **Headless**     | ✅                   | ❌                   | ❌      | データベース、StatefulSet | 無料   |
| **NodePort**     | ✅                   | ✅                   | ✅      | 開発環境、テスト          | 無料   |
| **LoadBalancer** | ✅                   | ✅                   | ✅      | 本番環境                  | 有料\* |
| **ExternalName** | ✅                   | -                    | ❌      | 外部サービス連携          | 無料   |

\*クラウドプロバイダーのロードバランサー料金が発生

---

## まとめ

各サービスタイプは異なる用途に適しています：

1. **ClusterIP**: クラスタ内部の通信に使用（最も一般的）
2. **Headless Service**: データベースなど、各 Pod に直接接続が必要な場合
3. **NodePort**: 開発環境やシンプルな構成で外部アクセスが必要な場合
4. **LoadBalancer**: 本番環境で安定した外部アクセスが必要な場合
5. **ExternalName**: クラスタ外部のサービスを参照する場合

用途に応じて適切なタイプを選択することが重要です。
