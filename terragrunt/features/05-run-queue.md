# Run Queue（実行キュー）

> 公式: https://terragrunt.gruntwork.io/docs/features/run-queue/

## 概要

**Run Queue** は、複数ユニットにまたがって OpenTofu/Terraform コマンドを実行する際の**実行順序と並行性**を管理する仕組みです。`run --all` や `run --graph` コマンドで使用されます。

## 動作原理: DAG（有向非巡回グラフ）

Run Queue は、`terragrunt.hcl` 内の `dependency` / `dependencies` ブロックから構築される DAG に基づいて動作します。

### 処理フロー

1. **Discovery（検出）** — 作業ディレクトリに基づいて対象ユニットを特定
2. **Queue Construction（キュー構築）** — コマンド種別に応じてユニットを順序付け
3. **Execution（実行）** — 並列数制限（`--parallelism`）に従い、依存の完了を待ってから実行

### コマンドによる実行順序の違い

| コマンド | 順序 |
|---------|------|
| `plan` / `apply` | 依存先 → 依存元 |
| `destroy` | 依存元 → 依存先（逆順） |

**例**: A → B → C の依存関係がある場合

```
plan/apply:   A(独立) と C(最上流) を同時実行 → B → 残り
destroy:      A(最下流) を先に実行 → B → C
```

## フィルタリング

### ポジティブフィルタ（指定パスを含む）

```bash
terragrunt run --all --filter './subtree/**' -- plan
```

### ネガティブフィルタ（指定パスを除外）

```bash
terragrunt run --all --filter '!./subtree/**' -- plan
```

### 組み合わせ

```bash
terragrunt run --all --filter './subtree/**' --filter '!./subtree/dependency/**' -- plan
```

## 実行順序の制御オプション

| フラグ | 説明 | 注意 |
|--------|------|------|
| `--queue-construct-as` | 特定コマンドの順序で構築。例: `terragrunt list --as destroy` | — |
| `--queue-ignore-dag-order` | DAG 順序を無視して並行実行 | `apply`/`destroy` では危険 |
| `--queue-ignore-errors` | ユニット失敗時も処理を継続 | ステート不整合の可能性 |
| `--fail-fast` | いずれかのユニット失敗時に即時停止 | — |

## 重要な注意事項

### 未デプロイの依存関係

`run --all plan` で依存先が未デプロイの場合、コマンドは失敗します。回避策として **mock outputs** を使用:

```hcl
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "mock-vpc-id"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}
```

### プロバイダキャッシュ

`run --all` で `TF_PLUGIN_CACHE_DIR` を設定すると並行アクセスで問題が発生します（OpenTofu >= 1.10 を除く）。代わりに Terragrunt の [Provider Cache Server](./15-provider-cache-server.md) を使用してください。

### 自動承認

`run --all` で `apply`/`destroy` を実行すると自動的に `-auto-approve` が付与されます。手動承認が必要な場合は `--no-auto-approve` を指定:

```bash
terragrunt run --all apply --no-auto-approve
```
