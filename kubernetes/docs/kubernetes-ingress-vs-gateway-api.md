# Kubernetes Ingress vs Gateway API 完全ガイド

> Kubernetes における外部トラフィック管理の2つのアプローチを徹底比較

## 目次

- [1. 概要](#1-概要)
- [2. アーキテクチャ比較](#2-アーキテクチャ比較)
- [3. Ingress API 詳細](#3-ingress-api-詳細)
- [4. Gateway API 詳細](#4-gateway-api-詳細)
- [5. 機能比較表](#5-機能比較表)
- [6. メリット・デメリット](#6-メリットデメリット)
- [7. ユースケース別推奨](#7-ユースケース別推奨)
- [8. 移行ガイドライン](#8-移行ガイドライン)
- [9. まとめ](#9-まとめ)

---

## 1. 概要

### 1.1 外部トラフィック管理の進化

```mermaid
timeline
    title Kubernetes 外部トラフィック管理の歴史
    2015 : Service (ClusterIP, NodePort, LoadBalancer)
    2016 : Ingress API Beta リリース
    2020 : Ingress API GA (v1)
    2021 : Gateway API Alpha リリース
    2022 : Gateway API Beta リリース
    2023 : Gateway API GA (v1.0)
    2024 : Gateway API 推奨化 : Ingress API 凍結
```

### 1.2 位置づけの違い

| 項目                    | Ingress API                  | Gateway API                    |
| ----------------------- | ---------------------------- | ------------------------------ |
| **ステータス**          | GA（凍結）                   | GA（活発に開発中）             |
| **API グループ**        | `networking.k8s.io/v1`       | `gateway.networking.k8s.io/v1` |
| **設計思想**            | シンプルな HTTP ルーティング | ロール指向・拡張可能           |
| **Kubernetes 公式推奨** | 非推奨（新規利用）           | **推奨**                       |

> **重要**: Kubernetes プロジェクトは Gateway API の使用を推奨しています。Ingress API は凍結されており、今後の機能追加は行われません。

---

## 2. アーキテクチャ比較

### 2.1 全体構成図

```mermaid
flowchart TB
    subgraph "Ingress アーキテクチャ"
        direction TB
        IC[IngressClass]
        I[Ingress]
        ICtrl[Ingress Controller]
        IS1[Service A]
        IS2[Service B]

        IC --> I
        I --> ICtrl
        ICtrl --> IS1
        ICtrl --> IS2
    end

    subgraph "Gateway API アーキテクチャ"
        direction TB
        GC[GatewayClass]
        G[Gateway]
        HR[HTTPRoute]
        GR[GRPCRoute]
        GCtrl[Gateway Controller]
        GS1[Service A]
        GS2[Service B]

        GC --> G
        G --> HR
        G --> GR
        HR --> GCtrl
        GR --> GCtrl
        GCtrl --> GS1
        GCtrl --> GS2
    end
```

### 2.2 リソース階層の違い

```mermaid
graph TB
    subgraph "Ingress（フラット構造）"
        direction TB
        I1[IngressClass] --> I2[Ingress]
        I2 --> I3[Rules/Paths]
        I3 --> I4[Backend Services]
    end

    subgraph "Gateway API（階層構造）"
        direction TB
        G1[GatewayClass] --> G2[Gateway]
        G2 --> G3[HTTPRoute / GRPCRoute / TLSRoute]
        G3 --> G4[Backend Services]
    end
```

### 2.3 ロール指向設計（Gateway API の特徴）

```mermaid
flowchart LR
    subgraph "インフラプロバイダー"
        GC[GatewayClass]
    end

    subgraph "クラスターオペレーター"
        G[Gateway]
    end

    subgraph "アプリケーション開発者"
        HR[HTTPRoute]
        GR[GRPCRoute]
    end

    GC -->|"実装を定義"| G
    G -->|"リスナーを公開"| HR
    G -->|"リスナーを公開"| GR
```

---

## 3. Ingress API 詳細

### 3.1 リソース構成

```mermaid
erDiagram
    IngressClass ||--o{ Ingress : "defines controller for"
    Ingress ||--o{ Rule : contains
    Rule ||--o{ Path : contains
    Path ||--|| Backend : "routes to"
    Backend ||--|| Service : references
    Ingress ||--o{ TLS : "optionally has"
    TLS ||--o{ Secret : references
```

### 3.2 基本的な Ingress マニフェスト

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
spec:
  controller: k8s.io/ingress-nginx
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    # コントローラー固有の設定はアノテーションで指定
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - example.com
      secretName: example-tls
  rules:
    - host: example.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 8080
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
```

### 3.3 Ingress のトラフィックフロー

```mermaid
sequenceDiagram
    participant Client as クライアント
    participant DNS as DNS
    participant LB as LoadBalancer
    participant IC as Ingress Controller
    participant Svc as Service
    participant Pod as Pod

    Client->>DNS: example.com 解決
    DNS-->>Client: IP アドレス
    Client->>LB: HTTPS リクエスト
    LB->>IC: TLS 終端
    IC->>IC: Ingress ルール評価
    IC->>Svc: マッチしたバックエンドへ転送
    Svc->>Pod: Pod へルーティング
    Pod-->>Client: レスポンス
```

---

## 4. Gateway API 詳細

### 4.1 リソースモデル

```mermaid
erDiagram
    GatewayClass ||--o{ Gateway : "configures"
    Gateway ||--o{ Listener : has
    Gateway ||--o{ HTTPRoute : "allows attachment of"
    Gateway ||--o{ GRPCRoute : "allows attachment of"
    Gateway ||--o{ TLSRoute : "allows attachment of"
    HTTPRoute ||--o{ Rule : contains
    Rule ||--o{ Match : contains
    Rule ||--o{ Filter : contains
    Rule ||--o{ BackendRef : "routes to"
    BackendRef ||--|| Service : references
```

### 4.2 Gateway API の主要リソース

#### GatewayClass（インフラプロバイダー管理）

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: example-gateway-class
spec:
  controllerName: example.com/gateway-controller
  parametersRef:
    group: example.com
    kind: GatewayConfig
    name: example-config
```

#### Gateway（クラスターオペレーター管理）

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: example-gateway
  namespace: gateway-system
spec:
  gatewayClassName: example-gateway-class
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      hostname: "*.example.com"
      allowedRoutes:
        namespaces:
          from: All
    - name: https
      protocol: HTTPS
      port: 443
      hostname: "*.example.com"
      tls:
        mode: Terminate
        certificateRefs:
          - name: example-cert
      allowedRoutes:
        namespaces:
          from: Selector
          selector:
            matchLabels:
              gateway-access: "true"
```

#### HTTPRoute（アプリケーション開発者管理）

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: example-route
  namespace: app-namespace
spec:
  parentRefs:
    - name: example-gateway
      namespace: gateway-system
  hostnames:
    - "api.example.com"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /v1
          headers:
            - name: X-API-Version
              value: v1
      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
              - name: X-Gateway-Route
                value: api-v1
      backendRefs:
        - name: api-v1-service
          port: 8080
          weight: 90
        - name: api-v2-service
          port: 8080
          weight: 10
```

### 4.3 Gateway API のトラフィックフロー

```mermaid
sequenceDiagram
    participant Client as クライアント
    participant DNS as DNS
    participant GW as Gateway
    participant Route as HTTPRoute
    participant Filter as Filter
    participant Svc as Service
    participant Pod as Pod

    Client->>DNS: api.example.com 解決
    DNS-->>Client: Gateway IP
    Client->>GW: HTTPS リクエスト
    GW->>GW: Listener マッチング
    GW->>Route: HTTPRoute ルール評価
    Route->>Route: Path/Header マッチング
    Route->>Filter: フィルター適用
    Filter->>Filter: ヘッダー変更等
    Filter->>Svc: 重み付けルーティング
    Svc->>Pod: Pod へ転送
    Pod-->>Client: レスポンス
```

### 4.4 その他の Route タイプ

```mermaid
graph TB
    G[Gateway] --> HR[HTTPRoute<br/>L7 HTTP/HTTPS]
    G --> GR[GRPCRoute<br/>L7 gRPC]
    G --> TR[TLSRoute<br/>L4 TLS パススルー]
    G --> TCP[TCPRoute<br/>L4 TCP]
    G --> UDP[UDPRoute<br/>L4 UDP]
```

---

## 5. 機能比較表

### 5.1 基本機能

| 機能                     | Ingress | Gateway API | 備考         |
| ------------------------ | :-----: | :---------: | ------------ |
| HTTP ルーティング        |   ✅    |     ✅      | 両方サポート |
| HTTPS/TLS 終端           |   ✅    |     ✅      | 両方サポート |
| パスベースルーティング   |   ✅    |     ✅      | 両方サポート |
| ホストベースルーティング |   ✅    |     ✅      | 両方サポート |
| 複数バックエンド         |   ✅    |     ✅      | 両方サポート |

### 5.2 高度な機能

| 機能                       | Ingress | Gateway API | 備考                            |
| -------------------------- | :-----: | :---------: | ------------------------------- |
| ヘッダーマッチング         |   ⚠️    |     ✅      | Ingress はアノテーション依存    |
| クエリパラメータマッチング |   ⚠️    |     ✅      | Ingress はアノテーション依存    |
| トラフィック重み付け       |   ⚠️    |     ✅      | Ingress はアノテーション依存    |
| リクエスト/レスポンス変換  |   ⚠️    |     ✅      | Gateway API は Filter で標準化  |
| gRPC サポート              |   ⚠️    |     ✅      | Gateway API は GRPCRoute で対応 |
| TCP/UDP ルーティング       |   ❌    |     ✅      | Gateway API のみ                |
| TLS パススルー             |   ⚠️    |     ✅      | Gateway API は TLSRoute で対応  |

### 5.3 運用・管理機能

| 機能                 | Ingress | Gateway API | 備考                             |
| -------------------- | :-----: | :---------: | -------------------------------- |
| ロール分離           |   ❌    |     ✅      | Gateway API の設計思想           |
| Namespace 分離       |   ⚠️    |     ✅      | Gateway API は標準でサポート     |
| ルートのアタッチ制御 |   ❌    |     ✅      | Gateway の allowedRoutes         |
| 実装間ポータビリティ |   ⚠️    |     ✅      | Ingress はアノテーション依存     |
| 適合性テスト         |   ❌    |     ✅      | Gateway API は公式テストスイート |

**凡例**: ✅ 標準サポート / ⚠️ 実装依存・アノテーション依存 / ❌ 非サポート

---

## 6. メリット・デメリット

### 6.1 Ingress API

```mermaid
mindmap
  root((Ingress API))
    メリット
      シンプルな設計
        学習コストが低い
        基本的なHTTPルーティングに最適
      広い採用実績
        成熟したエコシステム
        豊富なドキュメント
      軽量
        リソース1つで完結
        小規模環境に適合
    デメリット
      機能の限界
        HTTP/HTTPSのみ
        高度な機能はアノテーション依存
      ポータビリティ問題
        実装間で設定が異なる
        ベンダーロックイン懸念
      スケーラビリティ
        大規模環境では管理が複雑
        ロール分離が困難
      開発凍結
        新機能追加なし
        将来性に不安
```

#### Ingress のメリット詳細

| メリット         | 説明                                             |
| ---------------- | ------------------------------------------------ |
| **シンプルさ**   | 1つのリソースで HTTP ルーティングを定義可能      |
| **成熟度**       | 長年の実績があり、多くのコントローラーが対応     |
| **学習コスト**   | 概念がシンプルで理解しやすい                     |
| **既存資産**     | 多くの組織で既に導入済み                         |
| **ドキュメント** | 豊富なチュートリアルとトラブルシューティング情報 |

#### Ingress のデメリット詳細

| デメリット             | 説明                                       |
| ---------------------- | ------------------------------------------ |
| **機能制限**           | HTTP/HTTPS のみ、L4 ルーティング不可       |
| **アノテーション地獄** | 高度な機能は実装固有のアノテーションに依存 |
| **ポータビリティ**     | コントローラー間で設定が互換性なし         |
| **ロール分離不可**     | インフラ・オペレーター・開発者の責務が混在 |
| **凍結状態**           | 新機能追加なし、バグ修正のみ               |

### 6.2 Gateway API

```mermaid
mindmap
  root((Gateway API))
    メリット
      表現力
        豊富なマッチング条件
        ネイティブなトラフィック制御
        複数プロトコル対応
      ロール指向
        責務の明確な分離
        マルチテナント対応
        セキュリティ境界の明確化
      拡張性
        カスタムリソース対応
        ベンダー拡張可能
        将来の機能追加に柔軟
      ポータビリティ
        標準化されたAPI
        適合性テスト
        ベンダー間移行容易
    デメリット
      複雑性
        学習曲線が急
        リソースが多い
        初期設定が煩雑
      成熟度
        比較的新しい
        一部機能はBeta
        実績が少ない
      オーバーヘッド
        小規模には過剰
        追加CRDが必要
```

#### Gateway API のメリット詳細

| メリット             | 説明                                                     |
| -------------------- | -------------------------------------------------------- |
| **表現力**           | ヘッダー、クエリパラメータ、メソッドなど多様なマッチング |
| **ロール指向**       | インフラ/オペレーター/開発者の責務を明確に分離           |
| **マルチプロトコル** | HTTP、gRPC、TCP、UDP、TLS パススルーをサポート           |
| **ポータビリティ**   | 標準 API により実装間の移行が容易                        |
| **拡張性**           | Policy Attachment でカスタム機能を追加可能               |
| **トラフィック制御** | 重み付けルーティング、ミラーリングを標準サポート         |
| **Namespace 分離**   | クロスネームスペースのルーティングを安全に制御           |
| **将来性**           | 活発な開発、Kubernetes 公式推奨                          |

#### Gateway API のデメリット詳細

| デメリット           | 説明                                                     |
| -------------------- | -------------------------------------------------------- |
| **複雑性**           | 複数リソース（GatewayClass, Gateway, Route）の理解が必要 |
| **学習コスト**       | 新しい概念とパラダイムの習得が必要                       |
| **成熟度**           | 一部機能はまだ Beta または Experimental                  |
| **小規模への過剰性** | シンプルな要件には設定が冗長                             |
| **エコシステム**     | Ingress に比べて対応コントローラーが少ない               |
| **既存資産**         | Ingress からの移行作業が必要                             |

---

## 7. ユースケース別推奨

### 7.1 選択フローチャート

```mermaid
flowchart TD
    Start([プロジェクト開始]) --> Q1{新規プロジェクト?}

    Q1 -->|Yes| Q2{要件の複雑さは?}
    Q1 -->|No| Q3{現在 Ingress 使用中?}

    Q2 -->|シンプル<br/>HTTP/HTTPS のみ| Q4{将来の拡張予定?}
    Q2 -->|複雑<br/>gRPC/TCP/高度な制御| GW1[Gateway API 推奨]

    Q4 -->|あり| GW2[Gateway API 推奨]
    Q4 -->|なし| Either[どちらでも可<br/>Gateway API を検討]

    Q3 -->|Yes| Q5{問題はある?}
    Q3 -->|No| GW3[Gateway API 推奨]

    Q5 -->|機能不足| GW4[Gateway API へ移行検討]
    Q5 -->|ポータビリティ| GW5[Gateway API へ移行検討]
    Q5 -->|特になし| Keep[Ingress 継続<br/>移行計画策定]
```

### 7.2 シナリオ別推奨

| シナリオ                      | 推奨             | 理由                              |
| ----------------------------- | ---------------- | --------------------------------- |
| **新規 Web アプリケーション** | Gateway API      | 将来性、標準化されたAPI           |
| **マイクロサービス**          | Gateway API      | gRPC サポート、高度なルーティング |
| **マルチテナント環境**        | Gateway API      | ロール分離、Namespace 制御        |
| **既存 Ingress の拡張**       | Gateway API 移行 | 機能制限の回避                    |
| **シンプルな静的サイト**      | どちらでも可     | 要件次第だが Gateway API 推奨     |
| **レガシーシステム統合**      | Ingress 継続     | 移行コストとリスク考慮            |
| **L4 ロードバランシング**     | Gateway API      | TCP/UDP Route サポート            |

### 7.3 組織規模別推奨

```mermaid
graph LR
    subgraph "スタートアップ / 小規模"
        S1[シンプルな要件] --> S2[Gateway API<br/>学習投資は将来価値]
    end

    subgraph "中規模企業"
        M1[成長フェーズ] --> M2[Gateway API<br/>スケーラビリティ重視]
    end

    subgraph "大規模企業"
        L1[複雑な要件] --> L2[Gateway API<br/>ロール分離必須]
        L3[既存 Ingress 資産] --> L4[段階的移行計画]
    end
```

---

## 8. 移行ガイドライン

### 8.1 移行戦略

```mermaid
flowchart TB
    subgraph "Phase 1: 評価"
        P1A[現状分析] --> P1B[要件定義]
        P1B --> P1C[PoC 実施]
    end

    subgraph "Phase 2: 準備"
        P2A[Gateway API CRD インストール] --> P2B[GatewayClass 設定]
        P2B --> P2C[テスト環境構築]
    end

    subgraph "Phase 3: 移行"
        P3A[HTTPRoute 作成] --> P3B[並行稼働]
        P3B --> P3C[トラフィック切り替え]
    end

    subgraph "Phase 4: 完了"
        P4A[Ingress 削除] --> P4B[ドキュメント更新]
        P4B --> P4C[チーム教育]
    end

    P1C --> P2A
    P2C --> P3A
    P3C --> P4A
```

### 8.2 Ingress から HTTPRoute への変換例

#### Before: Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: example.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api-svc
                port:
                  number: 8080
```

#### After: Gateway API

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: example-gateway
spec:
  gatewayClassName: example-class
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      hostname: example.com
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: example-route
spec:
  parentRefs:
    - name: example-gateway
  hostnames:
    - example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
      filters:
        - type: URLRewrite
          urlRewrite:
            path:
              type: ReplacePrefixMatch
              replacePrefixMatch: /
      backendRefs:
        - name: api-svc
          port: 8080
```

### 8.3 移行時の注意点

| 注意点                       | 対策                                          |
| ---------------------------- | --------------------------------------------- |
| **アノテーションの互換性**   | Gateway API の Filter や Policy で代替        |
| **コントローラーの対応状況** | 使用コントローラーの Gateway API サポート確認 |
| **DNS 切り替え**             | 並行稼働期間を設けて段階的に移行              |
| **モニタリング設定**         | 新しいメトリクス・ログの設定                  |
| **チーム教育**               | Gateway API の概念とリソース構造の理解促進    |

---

## 9. まとめ

### 9.1 結論

```mermaid
graph TB
    subgraph "推奨事項"
        R1[新規プロジェクト] --> R2[Gateway API を採用]
        R3[既存 Ingress] --> R4[移行計画を策定]
        R5[複雑な要件] --> R6[Gateway API 必須]
    end

    subgraph "将来展望"
        F1[Ingress API 凍結] --> F2[Gateway API が標準]
        F3[エコシステム成熟] --> F4[より多くの採用]
    end
```

### 9.2 選択の指針

| 状況                    | 推奨                           |
| ----------------------- | ------------------------------ |
| **新規プロジェクト**    | **Gateway API** を強く推奨     |
| **既存 Ingress で満足** | 継続使用可能だが移行計画を検討 |
| **高度な機能が必要**    | **Gateway API** へ移行         |
| **マルチテナント**      | **Gateway API** 必須           |
| **L4 ルーティング**     | **Gateway API** 必須           |

### 9.3 キーメッセージ

> **Gateway API は Ingress の後継として設計された、より表現力豊かで拡張可能なAPI です。**
>
> Kubernetes プロジェクトは Gateway API の使用を推奨しており、Ingress API は凍結されています。
> 新規プロジェクトでは Gateway API を採用し、既存の Ingress 環境では計画的な移行を検討することを推奨します。

---

## 参考リンク

- [Kubernetes Gateway API 公式ドキュメント](https://gateway-api.sigs.k8s.io/)
- [Kubernetes Ingress 公式ドキュメント](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Gateway API 実装一覧](https://gateway-api.sigs.k8s.io/implementations/)
- [Ingress から Gateway API への移行ガイド](https://gateway-api.sigs.k8s.io/guides/migrating-from-ingress/)
- [Kubernetes 公式 Gateway API 解説（日本語）](https://kubernetes.io/ja/docs/concepts/services-networking/gateway/)

---

_最終更新: 2026年1月_
