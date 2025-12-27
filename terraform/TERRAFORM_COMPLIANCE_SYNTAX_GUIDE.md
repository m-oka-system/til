# terraform-compliance BDD 構文ガイド 🎯

terraform-compliance は **Gherkin** という自然言語に近い構文でテストを書きます。
Terraform の知識があれば、すぐに理解できます！

---

## 📐 基本構造

```
Feature: 何をテストするか（大カテゴリ）
  └── Scenario: 具体的なテストケース
        ├── Given: 対象リソースを指定
        ├── When: 条件を絞り込む（省略可）
        └── Then: 期待する結果を検証
```

---

## 📝 最小限の例

```gherkin
Feature: Storage Account のセキュリティ

  Scenario: HTTPS を強制する
    Given I have azurerm_storage_account defined    # 対象リソース
    Then it must contain https_traffic_only_enabled  # プロパティが存在すること
    And its value must be true                       # 値が true であること
```

これだけで「Storage Account に `https_traffic_only_enabled = true` が設定されているか」をテストできます！

---

## 🔑 キーワード早見表

| キーワード | 役割 | 日本語で言うと |
|-----------|------|---------------|
| `Feature` | テストの大分類 | 「〜のテスト」 |
| `Scenario` | 個別のテストケース | 「〜の場合」 |
| `Given` | 対象リソースを指定 | 「〜があるとき」 |
| `When` | 条件で絞り込む | 「〜の条件で」 |
| `Then` | 期待する結果 | 「〜であること」 |
| `And` | 前の行と同じ種類 | 「さらに」 |

---

## 🎯 Given（対象リソースの指定）

### 特定のリソースタイプを指定

```gherkin
# Azure のリソースタイプ名をそのまま使う
Given I have azurerm_storage_account defined
Given I have azurerm_key_vault defined
Given I have azurerm_virtual_network defined
Given I have azurerm_network_security_rule defined
```

### タグをサポートするすべてのリソース

```gherkin
Given I have resource that supports tags defined
```

### 任意のリソース

```gherkin
Given I have any resource defined
```

---

## 🔍 When（条件の絞り込み）

`When` は省略可能ですが、特定の条件に絞り込みたい時に使います。

### プロパティの値で絞り込む

```gherkin
# direction が "Inbound" のルールだけ対象
When its direction is "Inbound"

# access が "Allow" のルールだけ対象
When its access is "Allow"
```

### 複数条件を組み合わせる

```gherkin
Given I have azurerm_network_security_rule defined
When its direction is "Inbound"
When its access is "Allow"
Then ...  # Inbound かつ Allow のルールだけチェック
```

### プロパティが存在する場合のみ

```gherkin
# public_network_access_enabled がある場合だけチェック
When it has public_network_access_enabled
```

### 名前で絞り込む

```gherkin
# 名前が null でないリソースだけ
When its name is not null

# 名前に "prod" を含むリソースだけ
When its name contains "prod"
```

---

## ✅ Then（期待する結果の検証）

### プロパティが存在すること

```gherkin
Then it must contain https_traffic_only_enabled
Then it must contain tags
Then it must contain network_acls
```

### プロパティの値を検証

```gherkin
# 完全一致
Then its value must be true
Then its value must be false
Then its value must be "Deny"
Then its value must be "1.2"

# 部分一致
Then its value must contain "AzureServices"

# 正規表現マッチ
Then its value must match the "standard|premium" regex
Then its name must match the "^st.*" regex
```

### ネストしたプロパティ

```gherkin
# blob_properties の中の delete_retention_policy をチェック
Then it must contain blob_properties
And it must contain delete_retention_policy
```

### 禁止条件（〜であってはならない）

```gherkin
# 特定のポートが開いていないこと
Then its destination_port_range must not be "22"
Then its destination_port_range must not be "3389"
```

---

## 🏷️ タグの使い方

シナリオにタグを付けると、特定のテストだけ実行できます。

```gherkin
@storage @security
Feature: Storage Account Security

  @critical
  Scenario: HTTPS を強制する
    Given I have azurerm_storage_account defined
    Then it must contain https_traffic_only_enabled
    And its value must be true

  Scenario: 削除保護を設定する（重要度低め）
    Given I have azurerm_storage_account defined
    Then it must contain blob_properties
```

### タグ付きで実行

```bash
# @critical タグが付いたシナリオだけ実行
uvx terraform-compliance -f features -p tfplan.json --tags @critical

# @storage タグが付いたシナリオだけ実行
uvx terraform-compliance -f features -p tfplan.json --tags @storage
```

---

## 📚 実践パターン集

### パターン 1: 単純な true/false チェック

```gherkin
Scenario: RBAC 認証を使用する
  Given I have azurerm_key_vault defined
  Then it must contain rbac_authorization_enabled
  And its value must be true
```

**Terraform コードとの対応:**

```hcl
resource "azurerm_key_vault" "this" {
  rbac_authorization_enabled = true  # ← これをチェック
}
```

### パターン 2: 文字列の値チェック

```gherkin
Scenario: TLS 1.2 を使用する
  Given I have azurerm_mssql_server defined
  Then it must contain minimum_tls_version
  And its value must be "1.2"
```

**Terraform コードとの対応:**

```hcl
resource "azurerm_mssql_server" "this" {
  minimum_tls_version = "1.2"  # ← これをチェック
}
```

### パターン 3: 正規表現で複数の値を許可

```gherkin
Scenario: 適切な SKU を使用する
  Given I have azurerm_key_vault defined
  Then it must contain sku_name
  And its value must match the "standard|premium" regex
```

**Terraform コードとの対応:**

```hcl
resource "azurerm_key_vault" "this" {
  sku_name = "standard"  # "standard" または "premium" ならOK
}
```

### パターン 4: ネストしたブロックのチェック

```gherkin
Scenario: ネットワーク ACL を設定する
  Given I have azurerm_key_vault defined
  Then it must contain network_acls
  And it must contain default_action
  And its value must be "Deny"
```

**Terraform コードとの対応:**

```hcl
resource "azurerm_key_vault" "this" {
  network_acls {           # ← ブロックが存在すること
    default_action = "Deny"  # ← 値が "Deny" であること
  }
}
```

### パターン 5: 必須タグの存在確認

```gherkin
Scenario: project タグを持つ
  Given I have azurerm_resource_group defined
  Then it must contain tags
  And it must contain "project"
```

**Terraform コードとの対応:**

```hcl
resource "azurerm_resource_group" "this" {
  tags = {
    project = "my-project"  # ← "project" キーが存在すること
    env     = "dev"
  }
}
```

### パターン 6: 条件付きチェック

```gherkin
Scenario: パブリックアクセス時は IP フィルターを設定
  Given I have azurerm_cosmosdb_account defined
  When it has public_network_access_enabled
  When its value is true
  Then it must contain ip_range_filter
```

**意味:** パブリックアクセスが有効な場合のみ、IP フィルターの設定を要求

### パターン 7: Scenario Outline（複数値のテスト）

```gherkin
Scenario Outline: 危険なポートを禁止する
  Given I have azurerm_network_security_rule defined
  When its direction is "Inbound"
  When its access is "Allow"
  When its source_address_prefix is "*"
  Then its destination_port_range must not be "<port>"

  Examples:
    | port |
    | 22   |
    | 3389 |
    | 1433 |
```

**意味:** 同じテストを複数の値（22, 3389, 1433）で繰り返す

---

## ⚠️ よくある間違い

### ❌ リソース名を間違える

```gherkin
# NG: Azure Provider のリソース名と違う
Given I have storage_account defined

# OK: 正確なリソース名を使う
Given I have azurerm_storage_account defined
```

### ❌ プロパティ名を間違える

```gherkin
# NG: Terraform のプロパティ名と違う
Then it must contain httpsOnly

# OK: Terraform のプロパティ名を使う
Then it must contain https_traffic_only_enabled
```

### ❌ ネストの階層を飛ばす

```gherkin
# NG: いきなり深いプロパティを指定
Then it must contain delete_retention_policy

# OK: 親ブロックから順番に指定
Then it must contain blob_properties
And it must contain delete_retention_policy
```

---

## 🔗 参考リンク

- [terraform-compliance 公式ドキュメント](https://terraform-compliance.com/)
- [BDD リファレンス](https://terraform-compliance.com/pages/bdd-references/)
- [Azure Provider リソース一覧](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

## 💡 Tips

1. **まず Terraform コードを見る**: チェックしたいプロパティ名を確認
2. **シンプルに始める**: 最初は `Given` + `Then` だけで書く
3. **タグを活用**: `@critical` など重要度でグループ化
4. **エラーメッセージを読む**: 失敗時にどのリソースが問題か教えてくれる
