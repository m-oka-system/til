# CSI Secrets Store ドライバーの用途・仕組み・メリット

AKS で Key Vault のシークレットを Pod に渡す 2 通りの方法と、Secrets Store CSI Driver の役割を整理する。

---

## 1. 2 つの方式の違い

### 方式の概要

| 観点                         | アプリが Key Vault に直接アクセス          | CSI Secrets Store ドライバー                    |
| ---------------------------- | ------------------------------------------ | ----------------------------------------------- |
| Key Vault にアクセスする主体 | アプリ（Azure SDK）                        | CSI ドライバー＋ Azure Key Vault プロバイダー   |
| シークレットの渡し方         | アプリが API で取得                        | ファイルとしてマウント または K8s Secret に同期 |
| アプリの責務                 | Key Vault の URL・認証・リトライなどを実装 | ファイル／環境変数／K8s Secret を読むだけ       |

### アプリ直接アクセス（CSI なし）

アプリがプライベートエンドポイント経由で Key Vault API を呼ぶ構成。CSI がなくてもシークレットを参照できる。

```mermaid
flowchart LR
    subgraph Pod
        App[アプリ]
    end
    PE[プライベートエンドポイント]
    KV[(Key Vault)]

    App -->|"1. Azure SDK で API 呼び出し"| PE
    PE -->|"2. シークレット取得"| KV
    KV -->|"3. 応答"| App
```

### CSI ドライバー方式

Pod 起動時に CSI ドライバーが Key Vault から取得し、ファイルとしてマウントする。アプリは Key Vault を呼ばない。

```mermaid
flowchart LR
    subgraph Pod
        App[アプリ]
        Mount["/mnt/secrets-store/"]
    end
    CSI[Secrets Store<br/>CSI Driver]
    Provider[Azure Key Vault<br/>プロバイダー]
    KV[(Key Vault)]

    App -->|"ファイル読み取り"| Mount
    Mount -->|"Pod 起動時にマウント"| CSI
    CSI --> Provider
    Provider -->|"取得"| KV
```

---

## 2. CSI ドライバーの用途

**「アプリを Key Vault 非対応のまま、Key Vault の値を安全に渡したい」**ための仕組み。

- アプリはファイル・環境変数・Kubernetes Secret だけを扱う
- シークレットの取得とマウントはインフラ（CSI ドライバー）が担当

```mermaid
flowchart TB
    subgraph インフラの責務
        SPC[SecretProviderClass]
        CSI[CSI Driver]
        AKV[Key Vault]
        SPC --> CSI
        CSI --> AKV
    end

    subgraph アプリの責務
        Read[ファイル／env／K8s Secret を読む]
    end

    CSI -->|マウント or K8s Secret 同期| Read
```

---

## 3. 仕組み（処理の流れ）

### 3.1 Pod 起動時の流れ

```mermaid
sequenceDiagram
    participant K as kubelet
    participant CSI as Secrets Store CSI Driver
    participant P as Azure Key Vault プロバイダー
    participant KV as Key Vault
    participant App as アプリコンテナ

    K->>CSI: ボリュームのマウント要求
    CSI->>P: SecretProviderClass に従い取得依頼
    P->>KV: マネージド ID 等で認証・取得
    KV-->>P: シークレット
    P-->>CSI: ファイル内容
    CSI->>K: /mnt/secrets-store/ にマウント完了
    K->>App: コンテナ起動
    App->>App: ファイル or K8s Secret から読み取り
```

### 3.2 主なリソースの関係

```mermaid
flowchart TB
    SPC[SecretProviderClass<br/>Key Vault・オブジェクト・ID を定義]
    Pod[Pod の volume / volumeMount]
    KV[(Key Vault)]

    Pod -->|"csi タイプで参照"| SPC
    SPC -->|"指定に従い取得"| KV
```

### 3.3 認証

- **ノード**: アドオンが `azurekeyvaultsecretsprovider-xxx` のマネージド ID を VMSS に割り当て
- **Pod**: Workload Identity やユーザー割り当てマネージド ID を SecretProviderClass で指定

CSI を使う場合も、プライベートエンドポイント経由で Key Vault に到達する構成にできる。

---

## 4. CSI ドライバーのメリット

```mermaid
flowchart TB
    M1[アプリを Key Vault 非対応のまま運用]
    M2[K8s の volume / Secret に統合]
    M3[マウント・K8s Secret の自動ローテーション]
    M4[シークレットの一元管理]
    M5[キー・証明書のマウント]

    CSI[CSI Secrets Store Driver] --> M1
    CSI --> M2
    CSI --> M3
    CSI --> M4
    CSI --> M5
```

| メリット                            | 説明                                                                      |
| ----------------------------------- | ------------------------------------------------------------------------- |
| アプリを Key Vault 非対応のまま運用 | 既存の「ファイル・環境変数・K8s Secret を読む」アプリをそのまま利用可能   |
| K8s の volume / Secret に統合       | volume / volumeMount / env などの標準パターンで注入できる                 |
| 自動ローテーション                  | Key Vault の更新をマウント内容・K8s Secret に反映できる（制約あり）       |
| シークレットの一元管理              | SecretProviderClass でどの Key Vault のどのオブジェクトを参照するかを集約 |
| キー・証明書のマウント              | シークレットに加え、キーや証明書もファイルとしてマウント可能              |

---

## 5. 方式の比較（アプリ直接 vs CSI）

```mermaid
flowchart LR
    subgraph アプリ直接
        A1[実装が単純]
        A2[必要なときに取得]
        A3[CSI の制約なし]
    end

    subgraph CSI
        C1[レガシー・サードパーティ対応]
        C2[キー・証明書をファイル化]
        C3[K8s ネイティブな管理]
        C4[ローテーション支援]
    end
```

---

## 6. どちらを選ぶかの目安

| 向いているケース                                    | アプリ直接アクセス | CSI ドライバー |
| --------------------------------------------------- | ------------------ | -------------- |
| すでにアプリで Key Vault SDK を使っている           | ◎                  | △              |
| レガシー／サードパーティで Key Vault 対応が難しい   | △                  | ◎              |
| キー・証明書をファイルとして使いたい                | △                  | ◎              |
| K8s の volume / Secret / env に寄せたい             | △                  | ◎              |
| シークレットの自動ローテーションを K8s 側で扱いたい | △                  | ◎              |
| 構成をできるだけシンプルにしたい                    | ◎                  | △              |

---

## 7. まとめ

```mermaid
flowchart TB
    subgraph 現在の構成
        P1[Pod]
        PE1[プライベートエンドポイント]
        KV1[(Key Vault)]
        P1 -->|"アプリが Azure SDK で API 呼び出し"| PE1
        PE1 --> KV1
    end

    subgraph CSI 利用時
        P2[Pod]
        CSI2[CSI Driver]
        KV2[(Key Vault)]
        P2 -->|"ファイル／K8s Secret から読む"| CSI2
        CSI2 -->|"Pod 起動時に取得・マウント"| KV2
    end
```

- **現在の構成**: アプリがプライベートエンドポイント経由で Key Vault API を直接呼ぶため、CSI がなくてもシークレットを参照できる。
- **CSI の役割**: アプリを Key Vault 非対応のまま、**Pod 起動時に** CSI が Key Vault から取得し、ファイルまたは K8s Secret として渡す。
- **違い**: Key Vault への経路（プライベートエンドポイント）は共通。「誰が・いつ・どの形で」シークレットを取得してアプリに渡すかが、アプリ直接と CSI で異なる。

---

## 参考

- [AKS で Secrets Store CSI Driver 用 Azure Key Vault プロバイダーを使う \| Microsoft Learn](https://learn.microsoft.com/ja-jp/azure/aks/csi-secrets-store-driver)
- [AKS で Secrets Store CSI Driver 用 Azure Key Vault プロバイダーにアクセスする ID を提供する \| Microsoft Learn](https://learn.microsoft.com/ja-jp/azure/aks/csi-secrets-store-identity-access)
