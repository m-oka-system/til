# Units（ユニット）

> 公式: https://terragrunt.gruntwork.io/docs/features/units/

## 概要

**Unit（ユニット）**は、`terragrunt.hcl` ファイルを含むディレクトリであり、Terragrunt における**最小のデプロイ可能なインフラ単位**です。各ユニットは独立して操作でき、他のユニットに影響を与えません。

## 設計原則

| 原則 | 説明 |
|------|------|
| **密閉性（Hermetic）** | 各ユニットは他のユニットから独立して動作する |
| **アトミックな変更** | インフラの変更は再現可能で限定的なものになる |
| **単一インターフェース** | `terragrunt.hcl` が唯一の設定ポイント |
| **不変モジュール** | バージョン管理された OpenTofu/Terraform モジュールを使用 |

## なぜユニットが必要か

従来の IaC プロジェクトでは、環境ごとに設定をコピー＆ペーストする必要がありました。ユニットはリモートモジュール参照により、この重複を最小化します。

## 推奨ディレクトリ構成

**モジュールリポジトリ**（集中管理）:

```
modules/
├── app/
│   └── main.tf
├── mysql/
│   └── main.tf
└── vpc/
    └── main.tf
```

**ライブリポジトリ**（環境固有）:

```
live/
├── prod/
│   ├── app/
│   │   └── terragrunt.hcl
│   ├── mysql/
│   │   └── terragrunt.hcl
│   └── vpc/
│       └── terragrunt.hcl
├── qa/
│   ├── app/
│   │   └── terragrunt.hcl
│   ├── mysql/
│   │   └── terragrunt.hcl
│   └── vpc/
│       └── terragrunt.hcl
└── stage/
    ├── app/
    │   └── terragrunt.hcl
    ├── mysql/
    │   └── terragrunt.hcl
    └── vpc/
        └── terragrunt.hcl
```

## 設定例

**ステージング環境** (`stage/app/terragrunt.hcl`):

```hcl
terraform {
  source = "git::git@github.com:foo/modules.git//app?ref=v0.0.3"
}

inputs = {
  instance_count = 3
  instance_type  = "t4g.micro"
}
```

**本番環境** (`prod/app/terragrunt.hcl`):

```hcl
terraform {
  source = "git::git@github.com:foo/modules.git//app?ref=v0.0.1"
}

inputs = {
  instance_count = 10
  instance_type  = "m8g.large"
}
```

ポイント: 同じモジュールを参照しつつ、`ref` パラメータで異なるバージョンを、`inputs` で異なるパラメータを指定しています。

## Terragrunt の処理フロー

`terragrunt apply` を実行すると:

1. リモート設定を `.terragrunt-cache` にダウンロード（go-getter ライブラリ使用）
2. 現在のディレクトリのファイルを一時フォルダにコピー
3. `inputs` を `TF_VAR_` プレフィックス付き環境変数として設定
4. 指定された OpenTofu/Terraform コマンドを実行

## 不変モジュールとアトミックデプロイ

Git タグ（`ref` パラメータ）によるバージョン管理で以下が実現されます:

- **単一の信頼源** — モジュールコードの一元管理
- **一貫したプロモーション** — 環境間でのバージョン昇格
- **容易なロールバック** — バージョン参照を変更するだけ
- **再現可能なデプロイ** — 同一モジュールバージョンの使用保証

## ローカル開発

ローカルのモジュールコピーで高速にイテレーションするには `--source` フラグを使用:

```bash
cd live/stage/app
terragrunt apply --source ../../../modules//app
```

リモートからの再ダウンロードなしで即座にイテレーションできます。

## ロックファイル

Terraform 0.14 以降のロックファイル（`.terraform.lock.hcl`）は Terragrunt v0.27.0 以降で `terragrunt.hcl` ファイルの隣に自動生成されます。一貫性のためにバージョン管理に含めるべきです。

## キャッシュ戦略

| ソースタイプ | 動作 |
|-------------|------|
| リモート URL | URL が変更されない限り1回だけダウンロード |
| ローカルパス | 毎回コピー（高速イテレーション向き） |
| 強制更新 | `--source-update` フラグで再ダウンロード |

## ファイルパス管理

Terragrunt は一時ディレクトリから実行するため、パス管理に注意が必要です。

**コマンドライン**: 絶対パスを使用:

```bash
terragrunt apply -var-file /absolute/path/to/vars.tfvars
```

**設定ファイル内**: `get_terragrunt_dir()` 関数を使用:

```hcl
terraform {
  source = "git::git@github.com:foo/modules.git//app?ref=v0.0.3"

  extra_arguments "custom_vars" {
    commands = ["apply", "plan", "import"]
    arguments = [
      "-var-file=${get_terragrunt_dir()}/../common.tfvars",
      "-var-file=example.tfvars"
    ]
  }
}
```

## プライベート Git リポジトリ

SSH 認証を設定:

```hcl
terraform {
  source = "git@github.com:foo/modules.git//path/to/module?ref=v0.0.1"
}
```

CI/CD パイプラインでは事前に SSH ホストを登録:

```bash
ssh -T -oStrictHostKeyChecking=accept-new git@github.com || true
```

## Generate ブロック

不変モジュールに実行前に追加設定を注入します。典型的な用途はプロバイダ設定の動的生成です。

```hcl
# prod/env.hcl
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  assume_role {
    role_arn = "arn:aws:iam::0123456789:role/terragrunt"
  }
}
EOF
}
```

```hcl
# prod/app/terragrunt.hcl
include "env" {
  path = find_in_parent_folders("env.hcl")
}
```

`include` ブロックにより親フォルダの設定をコピーなしで再利用できます。
