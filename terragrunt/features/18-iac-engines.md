# IaC Engines（IaC エンジン）

> 公式: https://terragrunt.gruntwork.io/docs/features/engine/

## 概要

**IaC Engines** は、Terragrunt による Infrastructure as Code の更新オーケストレーションをカスタマイズする機能です。

> **実験的機能**: 本番環境での使用は推奨されていません。

## 有効化

```bash
export TG_EXPERIMENTAL_ENGINE=1
```

```hcl
engine {
  source  = "github.com/gruntwork-io/terragrunt-engine-opentofu"
  version = "v0.1.0"
}
```

## ユースケース

| ユースケース | 説明 |
|-------------|------|
| カスタムロギング/メトリクス | IaC バイナリ実行時に特殊な監視を出力 |
| リモート実行 | 別の環境（例: Kubernetes Pod）で IaC 操作を実行 |
| バージョンの柔軟性 | 統一デプロイメント内で異なるツールバージョンを使用 |

## ソースタイプ

### GitHub リポジトリ

```hcl
engine {
  source  = "github.com/gruntwork-io/terragrunt-engine-opentofu"
  version = "v0.1.0"
}
```

### HTTPS URL

```hcl
engine {
  source = "https://github.com/.../terragrunt-iac-engine-opentofu_rpc_v0.1.0_linux_amd64.zip"
}
```

### ローカルパス

```hcl
engine {
  source = "/home/users/iac-engines/terragrunt-iac-engine-opentofu_v0.1.0"
}
```

## 設定パラメータ

| パラメータ | 必須 | 説明 |
|-----------|------|------|
| `source` | はい | エンジンの場所（GitHub/HTTPS/ローカル） |
| `version` | いいえ | リリースバージョン（デフォルト: 最新） |
| `type` | いいえ | 現在 `rpc` のみ |
| `meta` | いいえ | エンジン固有の設定ブロック |

## メタデータ設定

エンジン固有の設定を `meta` ブロックで渡します:

```hcl
engine {
  source = "github.com/gruntwork-io/terragrunt-engine-opentofu"
  meta = {
    key_1 = ["value1", "value2"]
    key_2 = "1.6.0"
  }
}
```

接続設定、ツールバージョン、機能フラグなどを含められます。

## キャッシュと整合性

**キャッシュ場所**:

```
~/.cache/terragrunt/plugins/iac-engine/rpc/<version>
```

**カスタムキャッシュパス**:

```bash
export TG_ENGINE_CACHE_PATH=/custom/path
```

**SHA256 チェックサム検証**（デフォルト有効）の無効化:

```bash
export TG_ENGINE_SKIP_CHECK=0
```

**ログレベル設定**:

```bash
export TG_ENGINE_LOG_LEVEL=debug  # debug, info, warn, error
```
