# Includes（インクルード）

> 公式: https://terragrunt.gruntwork.io/docs/features/includes/

## 概要

**Includes** は、複数のユニット間で一貫した Terragrunt 設定を維持しながら、DRY（Don't Repeat Yourself）原則に従うための機能です。基本設定を集中管理ファイルに定義し、各ユニットで再利用できます。

## 基本的な使い方

**ベース設定ファイル** (`root.hcl`):

```hcl
remote_state {
  backend = "s3"
  config = {
    bucket         = "my-tofu-state"
    key            = "${path_relative_to_include()}/tofu.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "my-lock-table"
  }
}
```

**各ユニットでの参照**:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}
```

これだけで、すべてのユニットでリモートステート設定を共有できます。

## 複数 Include ブロック

コンポーネントタイプ固有の設定には、環境固有の設定ファイルを作成します。

**ディレクトリ構成**:

```
live/
├── root.hcl
├── _env/
│   ├── app.hcl
│   ├── mysql.hcl
│   └── vpc.hcl
├── prod/app/terragrunt.hcl
├── qa/app/terragrunt.hcl
└── stage/app/terragrunt.hcl
```

**共通ロジック** (`_env/app.hcl`):

```hcl
terraform {
  source = "github.com/<org>/modules.git//app?ref=v0.1.0"
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  basename = "example-app"
  vpc_id   = dependency.vpc.outputs.vpc_id
}
```

**各ユニット** (`qa/app/terragrunt.hcl`):

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "env" {
  path = "${get_terragrunt_dir()}/../../_env/app.hcl"
}

inputs = {
  env = "qa"
}
```

root（全体共通）と env（コンポーネント共通）の2つの include を組み合わせています。

## Exposed Includes

子設定が親の値をオーバーライドまたは拡張する必要がある場合、`expose = true` を設定します。

**親設定** (`_env/app.hcl`):

```hcl
locals {
  source_base_url = "github.com/<org>/modules.git//app"
}
```

**子設定**:

```hcl
include "env" {
  path   = "${get_terragrunt_dir()}/../../_env/app.hcl"
  expose = true
}

terraform {
  source = "${include.env.locals.source_base_url}?ref=v0.2.0"
}
```

`include.env.locals.source_base_url` で親の locals にアクセスし、ソース URL を重複記述せずにバージョンだけをオーバーライドできます。

## read_terragrunt_config による動的設定

環境固有の値に依存する入力には、`read_terragrunt_config` で動的にコンテキストを読み込みます。

**環境固有ファイル** (`qa/env.hcl`):

```hcl
locals {
  env = "qa"
}
```

**共有 include ファイル** (`_env/app.hcl`):

```hcl
locals {
  env_vars = read_terragrunt_config(
    find_in_parent_folders("env.hcl")
  )
  env_name = local.env_vars.locals.env
}

inputs = {
  env      = local.env_name
  basename = "example-app-${local.env_name}"
}
```

どのユニットをデプロイしても、正しい環境コンテキストが自動的に適用されます。

## CI/CD パイプラインとの連携

include ファイルを変更した場合、直接変更していないユニットにも影響する可能性があります。`--queue-include-units-reading` フラグで影響を受けるすべてのユニットを自動検出します:

```bash
# 影響を受ける全ユニットの plan
terragrunt run --all plan --queue-include-units-reading _env/app.hcl
```

**段階的ロールアウト**（`--working-dir` でスコープを限定）:

```bash
# qa 環境のみ
terragrunt run --all plan  --queue-include-units-reading _env/app.hcl --working-dir qa
terragrunt run --all apply --queue-include-units-reading _env/app.hcl --working-dir qa

# 確認後、stage へ
terragrunt run --all plan  --queue-include-units-reading _env/app.hcl --working-dir stage
terragrunt run --all apply --queue-include-units-reading _env/app.hcl --working-dir stage
```

qa → stage → prod と段階的に変更を進められます。
