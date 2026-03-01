# State Backend（ステートバックエンド）

> 公式: https://terragrunt.gruntwork.io/docs/features/state-backend/

## 概要

Terragrunt はリモートステート設定を複数モジュール間で重複なく管理する仕組みを提供します。OpenTofu/Terraform のバックエンド設定は式・変数・関数を使用できないため、同一設定を各モジュールにコピーする必要がありました。

## 問題点

複数モジュール（backend-app, frontend-app, mysql, vpc など）がある場合、各 `main.tf` に同一のバックエンド設定が必要です:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-tofu-state"
    key            = "frontend-app/tofu.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "my-lock-table"
  }
}
```

違いは通常 `key` パラメータだけです。さらに、S3 バケットや DynamoDB テーブルなどのバックエンドリソースを別途プロビジョニングする必要があります。

## 解決策 1: Generate ブロック

`root.hcl` にバックエンド設定を一度だけ定義:

```hcl
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket         = "my-tofu-state"
    key            = "${path_relative_to_include()}/tofu.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "my-lock-table"
  }
}
EOF
}
```

各モジュールの `terragrunt.hcl` で継承:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}
```

**重要な関数**:
- `find_in_parent_folders()` — ルート設定ファイルを探索
- `path_relative_to_include()` — モジュールごとにユニークなステートキーを生成

## 解決策 2: remote_state ブロック（リソース自動作成）

`remote_state` ブロックはバックエンドリソースを自動的にプロビジョニングします:

```hcl
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "my-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "my-lock-table"
  }
}
```

S3 バケットと DynamoDB テーブルが、バージョニング・暗号化・アクセスログ付きで自動作成されます。

## サポートされるバックエンド

| バックエンド | 自動リソース作成 |
|-------------|----------------|
| S3 (AWS) | 対応 |
| GCS (Google Cloud) | 対応 |
| その他 | `generate` ブロックと同等の動作 |

## S3 固有オプション

```hcl
remote_state {
  backend = "s3"
  config = {
    # ... 基本設定 ...
    skip_bucket_versioning    = false
    skip_bucket_ssencryption  = false
    accesslogging_bucket_name = "my-access-logs"
    s3_bucket_tags = {
      Environment = "production"
    }
    dynamodb_table_tags = {
      Environment = "production"
    }
  }
}
```

## GCS 固有オプション

```hcl
remote_state {
  backend = "gcs"
  config = {
    bucket                  = "my-tofu-state"
    skip_bucket_versioning  = false
    enable_bucket_policy_only = true
    encryption_key          = "projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key"
    gcs_bucket_labels = {
      environment = "production"
    }
  }
}
```

## 自動ブートストラップの無効化

CI パイプラインなどで自動リソース作成をスキップするには:

```hcl
remote_state {
  # ...
  disable_init = true
}
```

OpenTofu/Terraform のバックエンド初期化は通常通り行われますが、リソースの自動作成はスキップされます。
