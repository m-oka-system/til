# Hooks（フック）

> 公式: https://terragrunt.gruntwork.io/docs/features/hooks/

## 概要

**Hooks** は、OpenTofu/Terraform コマンドの**実行前・実行後・エラー発生時**にカスタムアクションを実行する機能です。IaC 更新に関連するオペレーションのオーケストレーションを可能にします。

## フックの種類

| 種類 | タイミング | 用途 |
|------|----------|------|
| `before_hook` | コマンド実行前 | 前処理、バリデーション |
| `after_hook` | コマンド実行後 | 後処理、通知 |
| `error_hook` | エラー発生時 | エラーハンドリング |

## 基本例

```hcl
terraform {
  before_hook "before_hook" {
    commands = ["apply", "plan"]
    execute  = ["echo", "Running OpenTofu"]
  }

  after_hook "after_hook" {
    commands     = ["apply", "plan"]
    execute      = ["echo", "Finished running OpenTofu"]
    run_on_error = true
  }

  error_hook "import_resource" {
    commands  = ["apply"]
    execute   = ["echo", "Error Hook executed"]
    on_errors = [".*"]
  }
}
```

## フックコンテキスト

フック実行時に以下の環境変数が自動注入されます:

| 環境変数 | 内容 |
|---------|------|
| `TG_CTX_TF_PATH` | terraform/tofu 実行ファイルのパス |
| `TG_CTX_COMMAND` | 実行中のコマンド |
| `TG_CTX_HOOK_NAME` | フックの識別名 |

**コンテキスト活用例**:

```bash
# フック内で terraform output にアクセス
BUCKET_NAME="$("$TG_CTX_TF_PATH" output -raw bucket_name)"
aws s3 ls "s3://$BUCKET_NAME"
```

`terragrunt.hcl` の `inputs` も `TF_VAR_` プレフィックス付き環境変数として利用可能です。

## 実用的なユースケース

### デプロイ前の Docker イメージビルド

```hcl
terraform {
  before_hook "build_and_push_image" {
    commands = ["plan", "apply"]
    execute  = ["./build_and_push_image.sh"]
  }
}
```

### デプロイ後のスモークテスト

```hcl
terraform {
  after_hook "smoke_test" {
    commands     = ["apply"]
    execute      = ["./smoke_test.sh"]
    run_on_error = true
  }
}
```

## フックの実行順序

複数のフックは定義順に順次実行されます:

```hcl
terraform {
  before_hook "before_hook_1" {
    commands = ["apply", "plan"]
    execute  = ["echo", "Will run OpenTofu"]
  }

  before_hook "before_hook_2" {
    commands = ["apply", "plan"]
    execute  = ["echo", "Running OpenTofu"]
  }
}
```

出力: `Will run OpenTofu` → `Running OpenTofu`

## tflint との統合

Terragrunt は tflint（OpenTofu/Terraform リンター）とのネイティブ統合を提供します。

### 基本設定

```hcl
terraform {
  before_hook "before_hook" {
    commands = ["apply", "plan"]
    execute  = ["tflint"]
  }
}
```

### .tflint.hcl の設定

```hcl
plugin "aws" {
  enabled = true
  version = "0.21.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

config {
  module = true
}
```

### カスタム設定ファイル

```hcl
terraform {
  before_hook "tflint" {
    commands = ["apply", "plan"]
    execute  = ["tflint", "--minimum-failure-severity=error", "--config", "custom.tflint.hcl"]
  }
}
```

### トラブルシューティング

`"flag provided but not defined: -act-as-bundled-plugin"` エラーが出た場合、`.tflint.hcl` が空か terraform ruleset にバージョン制約がないことが原因です:

```hcl
plugin "terraform" {
  enabled = true
  version = "0.2.1"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}
```
