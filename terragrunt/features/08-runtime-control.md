# Runtime Control（ランタイム制御）

> 公式: https://terragrunt.gruntwork.io/docs/features/runtime-control/

## 概要

Terragrunt は3つの設定ブロックを組み合わせて、柔軟なランタイム動作管理を提供します:

1. **Feature Flags** — フィーチャーフラグ
2. **Error Handling** — エラー制御
3. **Exclusions** — 除外制御

---

## 1. Feature Flags（フィーチャーフラグ）

`feature` ブロックを使用して、実行時の動作を制御します。

### 基本例: モジュールバージョンの動的制御

```hcl
feature "s3_version" {
  default = "v1.0.0"
}

terraform {
  source = "git::git@github.com:acme/infrastructure-modules.git//storage/s3?ref=${feature.s3_version.value}"
}
```

### ランタイムでのオーバーライド

**CLI フラグ**:

```bash
terragrunt apply --feature s3_version=v1.1.0
```

**環境変数**:

```bash
export TG_FEATURE="s3_version=v1.1.0"
terragrunt apply
```

下位環境で新バージョンをテストしてから本番にロールアウトする際に便利です。

---

## 2. Error Handling（エラー制御）

`errors` ブロックでランタイムエラーへの応答を細かく制御します。

### retry（自動リトライ）

一時的なエラーを自動的にリトライ:

```hcl
errors {
  retry "transient_errors" {
    retryable_errors   = [".*Error: transient network issue.*"]
    max_attempts       = 3
    sleep_interval_sec = 5
  }
}
```

| パラメータ | 説明 |
|-----------|------|
| `retryable_errors` | リトライ対象の正規表現パターンのリスト |
| `max_attempts` | 最大リトライ回数 |
| `sleep_interval_sec` | リトライ間の待機秒数 |

### ignore（エラー無視）

既知の安全なエラーを抑制:

```hcl
errors {
  ignore "known_safe_errors" {
    ignorable_errors = [".*Error: safe warning.*"]
    message          = "Ignoring safe warning errors"
    signals          = { alert_team = false }
  }
}
```

### 組み合わせ例

```hcl
errors {
  retry "transient_errors" {
    retryable_errors   = [".*Error: transient network issue.*"]
    max_attempts       = 3
    sleep_interval_sec = 5
  }

  ignore "known_safe_errors" {
    ignorable_errors = [".*Error: safe warning.*"]
    message          = "Ignoring safe warning errors"
    signals          = { alert_team = false }
  }
}
```

---

## 3. Exclusions（除外制御）

`exclude` ブロックで特定のコンテキスト（特に `run --all`）でユニットの実行を防止します。

### 動的除外: 曜日による制限

```hcl
locals {
  day_of_week = formatdate("EEE", timestamp())
  ban_deploy  = contains(["Fri", "Sat", "Sun"], local.day_of_week)
}

exclude {
  if      = local.ban_deploy
  actions = ["apply", "destroy"]
}
```

金曜・土曜・日曜のデプロイを禁止する例です。

### 環境ベースのオプトインパターン

```hcl
# dev/root.hcl
feature "dev" { default = true }

exclude {
  if      = !feature.dev.value
  actions = ["all_except_output"]
}
```

```hcl
# stage/root.hcl
feature "stage" { default = false }

exclude {
  if      = !feature.stage.value
  actions = ["all_except_output"]
}
```

**選択的な環境の有効化**:

```bash
# stage のみ有効化
terragrunt run --all --feature stage=true plan

# dev を無効化して stage を有効化
terragrunt run --all --feature dev=false --feature stage=true plan
```

### 重要な制限

除外は `run --all` コマンドにのみ影響します。ユニットのディレクトリに直接移動してコマンドを実行すると、除外は適用されません。絶対的な防止が必要な場合は `before_hook` と組み合わせてください。
