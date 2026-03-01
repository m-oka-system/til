# Stacks（スタック）

> 公式: https://terragrunt.gruntwork.io/docs/features/stacks/

## 概要

**Stack（スタック）**は、関連するユニットの集合であり、まとめて管理できる単位です。複数のインフラコンポーネントの同時デプロイ、依存関係の自動管理、変更範囲の制御、インフラの論理的な整理を可能にします。

## 2つのスタック方式

### 暗黙的スタック（Implicit Stacks）

ディレクトリ構成から自然に形成されるスタックです。ディレクトリに `terragrunt.hcl` ファイルを配置するだけで、Terragrunt がそのディレクトリをデプロイ可能なスタックとして扱います。

**特徴**:
- 最もシンプルな実装方法
- 馴染みのあるディレクトリベースの構成
- 約8年の実績ある採用歴

**使用例**:

```bash
# カレントディレクトリ内の全ユニットをデプロイ
terragrunt run --all apply

# 全ユニットで plan を実行
terragrunt run --all plan
```

**利点**: シンプルさ、透明性、バージョン管理との親和性、後方互換性

**制限**: 手動設定が必要、パターンの再利用不可、環境間で設定が重複

### 明示的スタック（Explicit Stacks）

`terragrunt.stack.hcl` というブループリントファイルを使い、プログラム的にユニットを生成します。環境間でパターンを共有できます。

**設定ブロック**:
- **`unit` ブロック**: 単一のインフラコンポーネントを定義
- **`stack` ブロック**: 再利用可能なマルチユニットパターンを定義

**unit 定義例**:

```hcl
unit "vpc" {
  source = "git::git@github.com:acme/infrastructure-catalog.git//units/vpc?ref=v0.0.1"
  path   = "vpc"
  values = {
    vpc_name = "main"
    cidr     = "10.0.0.0/16"
  }
}
```

**ネストされた stack 例**:

```hcl
stack "dev" {
  source = "git::git@github.com:acme/infrastructure-catalog.git//stacks/environment?ref=v0.0.1"
  path   = "dev"
  values = {
    environment = "development"
    cidr        = "10.0.0.0/16"
  }
}
```

**生成ワークフロー**:

```bash
# ブループリントからユニットを生成
terragrunt stack generate

# 生成された全ユニットをデプロイ
terragrunt stack run apply
```

## スタック方式の選択ガイド

| 観点 | 暗黙的スタック | 明示的スタック |
|------|--------------|--------------|
| ユニット数 | 少数 | 多数 |
| 環境の独自性 | 環境ごとにユニーク | パターンの再利用 |
| 透明性 | 最大限 | やや複雑 |
| 適用場面 | 初期導入 | 成熟したプロジェクト |

## 依存関係管理

### ユニット間の出力受け渡し

`dependency` ブロックで他ユニットの出力を参照:

```hcl
dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
}
```

### モック出力（未デプロイの依存関係用）

依存先が未適用でも plan/validate を実行可能:

```hcl
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "mock-vpc-id"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}
```

### 依存関係の宣言

実行順序を明示的に指定:

```hcl
dependencies {
  paths = ["../vpc", "../mysql", "../valkey"]
}
```

`run --all apply` 時の正しい実行順序を保証します。

## 高度な機能

### スタック出力の集約

```bash
terragrunt stack output --format json
```

### DAG の可視化

```bash
terragrunt dag graph | dot -Tsvg > graph.svg
```

### 並列実行数の制御

```bash
terragrunt run --all apply --parallelism 4
```

### Plan 出力の保存

```bash
terragrunt run --all plan --out-dir /tmp/tfplan
```

### ローカルステート設定

スタック再生成間で永続的なステートを維持:

```hcl
remote_state {
  backend = "local"
  config = {
    path = "${get_parent_terragrunt_dir()}/.terragrunt-local-state/${path_relative_to_include()}/tofu.tfstate"
  }
}
```

## 明示的スタックの既知の制限

1. **スタック間依存関係**: 別のスタックへの `config_path` 参照は不可
2. **生成パフォーマンス**: 深いネストではネットワーク/ファイルシステム操作により速度低下
3. **include 非サポート**: `terragrunt.stack.hcl` 内では `include` ブロック未対応

## ネストされたスタック

スタックは階層的な構成をサポートし、任意の深さで `run --all` コマンドを実行するとそのスタックとその子孫のユニットのみが実行されます。これにより**影響範囲（blast radius）**を制御できます。
