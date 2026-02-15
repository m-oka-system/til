# AKS ネットワーク アドレス空間の図解

> 調査日: 2026-02-14

## Overlay モードの全体像

AKS Overlay モードでは、ノード IP は VNet サブネットから、Pod IP と Service IP はそれぞれ独立した仮想空間から割り当てられます。

```mermaid
graph TB
    subgraph VNet["VNet アドレス空間（10.10.0.0/16）"]
        subgraph NodeSubnet["AKS サブネット（10.10.12.0/24）"]
            Node1["ノード1<br/>10.10.12.4"]
            Node2["ノード2<br/>10.10.12.5"]
            Node3["ノード3<br/>10.10.12.6"]
        end
    end

    subgraph PodCIDR["pod_cidr（10.244.0.0/16）— 仮想空間"]
        subgraph N1Pods["ノード1 に割当: /24"]
            CoreDNS["coredns Pod<br/>10.244.0.12"]
            KubeProxy["kube-proxy Pod<br/>10.244.0.15"]
        end
        subgraph N2Pods["ノード2 に割当: /24"]
            MyApp["my-app Pod<br/>10.244.1.10"]
        end
    end

    subgraph ServiceCIDR["service_cidr（10.96.0.0/16）— 仮想空間"]
        KubeDNSSvc["kube-dns Service<br/>10.96.0.10（= dns_service_ip）"]
        MyAppSvc["my-app Service<br/>10.96.0.50"]
    end

    Node1 --> N1Pods
    Node2 --> N2Pods
    MyApp -- "DNS クエリ" --> KubeDNSSvc
    KubeDNSSvc -- "kube-proxy 転送" --> CoreDNS
    MyAppSvc -- "kube-proxy 転送" --> MyApp
```

## DNS 解決フロー

Pod がサービス名で通信する際、CoreDNS が名前を ClusterIP に解決し、kube-proxy が実際の Pod IP に転送します。

```mermaid
sequenceDiagram
    participant App as my-app Pod<br/>10.244.1.10
    participant KP as kube-proxy<br/>(iptables)
    participant DNS as CoreDNS Pod<br/>10.244.0.12
    participant Svc as my-api Service<br/>10.96.0.50
    participant API as my-api Pod<br/>10.244.1.20

    App->>KP: DNS クエリ 宛先: 10.96.0.10<br/>"my-api.default.svc.cluster.local"
    KP->>DNS: 転送: 10.96.0.10 → 10.244.0.12
    DNS-->>App: 応答: ClusterIP 10.96.0.50
    App->>KP: HTTP リクエスト 宛先: 10.96.0.50
    KP->>API: 転送: 10.96.0.50 → 10.244.1.20
    API-->>App: HTTP レスポンス
```

## 3 つのアドレス空間の対比

3 つの CIDR は相互に重複できません。ノード CIDR のみ VNet 上の実 IP で、残り 2 つはクラスター内部の仮想空間です。

```mermaid
graph LR
    subgraph Real["実ネットワーク（VNet 上）"]
        NodeIP["ノード IP<br/>10.10.12.0/24"]
    end

    subgraph Virtual1["仮想空間 1（クラスター内部）"]
        PodIP["Pod IP<br/>10.244.0.0/16<br/>全 Pod に割当"]
    end

    subgraph Virtual2["仮想空間 2（クラスター内部）"]
        SvcIP["Service ClusterIP<br/>10.96.0.0/16<br/>Service に割当"]
    end

    NodeIP -. "重複 NG" .-> PodIP
    PodIP -. "重複 NG" .-> SvcIP
    NodeIP -. "重複 NG" .-> SvcIP
```

## アドレス空間の対応表

| 空間         | 範囲例          | 存在場所         | 割り当て対象            |
| ------------ | --------------- | ---------------- | ----------------------- |
| ノード CIDR  | `10.10.12.0/24` | VNet 上（実 IP） | AKS ノード VM           |
| pod_cidr     | `10.244.0.0/16` | 仮想空間         | 全 Pod（system + user） |
| service_cidr | `10.96.0.0/16`  | 仮想空間         | Service の ClusterIP    |

## 参考リンク

- [AKS ネットワーク概念](https://learn.microsoft.com/en-us/azure/aks/concepts-network)
- [Azure CNI Overlay 概要](https://learn.microsoft.com/en-us/azure/aks/concepts-network-azure-cni-overlay)
- [Azure CNI Overlay 構成](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay)
- [AKS IP アドレス計画](https://learn.microsoft.com/en-us/azure/aks/concepts-network-ip-address-planning)
- [CNI ネットワーク概要](https://learn.microsoft.com/en-us/azure/aks/concepts-network-cni-overview)
