# Extra Arguments（追加引数）

> 公式: https://terragrunt.gruntwork.io/docs/features/extra-arguments/

## 概要

**Extra Arguments** は、OpenTofu/Terraform コマンドに自動的に適用される CLI フラグを定義する機能です。毎回同じフラグを手動入力する手間を省き、設定を DRY に保ちます。

## 基本構造

```hcl
terraform {
  extra_arguments "<ラベル>" {
    commands  = [<対象コマンドのリスト>]
    arguments = [<追加するフラグのリスト>]
    env_vars  = {  # オプション
      <環境変数名> = "<値>"
    }
  }
}
```

## 実用例: ロックタイムアウト

```hcl
terraform {
  extra_arguments "retry_lock" {
    commands = [
      "init", "apply", "refresh", "import", "plan", "taint", "untaint"
    ]
    arguments = ["-lock-timeout=20m"]
    env_vars = {
      TF_VAR_var_from_environment = "value"
    }
  }
}
```

`terragrunt apply` 実行時、実際には `tofu apply -lock-timeout=20m` が実行されます。

## 複数ブロックの組み合わせ

複数の `extra_arguments` ブロックは定義順に適用されます:

```hcl
terraform {
  extra_arguments "retry_lock" {
    commands  = get_terraform_commands_that_need_locking()
    arguments = ["-lock-timeout=20m"]
  }

  extra_arguments "custom_vars" {
    commands  = ["apply", "plan", "import", "push", "refresh"]
    arguments = ["-var", "foo=bar", "-var", "region=us-west-1"]
  }
}
```

結果: `tofu apply -lock-timeout=20m -var foo=bar -var region=us-west-1`

## tfvars ファイルの管理

### required_var_files（必須）

ファイルが存在しない場合はエラー:

```hcl
terraform {
  extra_arguments "required_vars" {
    commands = ["apply", "plan"]
    required_var_files = [
      "${get_parent_terragrunt_dir()}/tofu.tfvars"
    ]
  }
}
```

### optional_var_files（任意）

ファイルが存在しない場合は黙ってスキップ:

```hcl
terraform {
  extra_arguments "conditional_vars" {
    commands = ["apply", "plan", "import", "push", "refresh"]
    optional_var_files = [
      "${get_parent_terragrunt_dir("root")}/${get_env("TF_VAR_env", "dev")}.tfvars"
    ]
  }
}
```

## init コマンドの注意点

`init` 用の `extra_arguments` は、明示的な `terragrunt init` 呼び出しと、他のコマンド実行時の自動 init の**両方**に適用されます。

`-from-module` や `DIR` 引数は**指定しないでください** — Terragrunt が自動的に処理します。

## スペースを含む引数

スペースを含む引数は個別のリスト要素として分離:

```hcl
terraform {
  extra_arguments "bucket" {
    commands  = ["apply", "plan", "import", "push", "refresh"]
    arguments = ["-var", "bucket=example.bucket.name"]
  }
}
```

`["-var bucket=example.bucket.name"]` ではなく、`["-var", "bucket=example.bucket.name"]` のように分けてください。
