# Auto Init（自動初期化）

> 公式: https://terragrunt.gruntwork.io/docs/features/auto-init/

## 概要

**Auto Init** は、`terragrunt init` を明示的に実行しなくても、他のコマンド実行前に自動的に初期化を行う機能です。デフォルトで有効になっています。

## 自動初期化のトリガー条件

以下のいずれかを検出した場合に `tofu init` / `terraform init` が自動実行されます:

| 条件 | 説明 |
|------|------|
| 初回実行 | 初期化がまだ行われていない |
| ソースコードの変更 | ダウンロードが必要なソースの検出 |
| `.terragrunt-init-required` | キャッシュディレクトリ内にこのファイルが存在 |
| モジュール/ステートの変更 | 前回の初期化からモジュールやリモートステートが変更された |

## init のカスタマイズ

`extra_arguments` で `tofu init` の実行方法をカスタマイズできます:

```hcl
terraform {
  extra_arguments "init_args" {
    commands = ["init"]
    arguments = ["-upgrade"]
  }
}
```

## 制限事項

Auto Init が `tofu init` の必要性を検出できないケースがあります。その場合、OpenTofu/Terraform が失敗し、手動で `terragrunt init` を再実行することで解決できます。

## 無効化方法

### コマンドラインフラグ

```bash
terragrunt apply --no-auto-init
```

### 環境変数

```bash
export TG_NO_AUTO_INIT=true
terragrunt apply
```

無効化した場合、開発者は手動で `terragrunt init` を先に実行する必要があります。初期化なしで他のコマンドを実行するとエラーが発生します。
