# Debugging（デバッグ）

> 公式: https://terragrunt.gruntwork.io/docs/features/debugging/

## 概要

Terragrunt は、インフラコード・Terragrunt 設定・OpenTofu/Terraform の動作に関する問題を特定・解決するための包括的なデバッグ機能を提供します。

## ログレベルの設定

最も基本的なデバッグ手法です:

```bash
terragrunt run --log-level debug -- plan
```

冗長性を上げることで、Terragrunt の操作や意思決定プロセスに関する追加情報が出力されます。

## テレメトリと分散トレーシング

### OpenTelemetry + Jaeger 統合

より深い運用インサイトを得るため、OpenTelemetry と Jaeger トレーシングを統合できます。

**Jaeger コンテナの起動**:

```bash
docker run --rm --name jaeger \
  -e COLLECTOR_OTLP_ENABLED=true \
  -p 16686:16686 \
  -p 4317:4317 \
  -p 4318:4318 \
  jaegertracing/all-in-one:1.54.0
```

**テレメトリ環境変数の設定**:

```bash
export TG_TELEMETRY_TRACE_EXPORTER=http
export TG_TELEMETRY_TRACE_EXPORTER_HTTP_ENDPOINT=localhost:4318
export TG_TELEMETRY_TRACE_EXPORTER_INSECURE_ENDPOINT=true
```

**通常通り Terragrunt を実行**:

```bash
terragrunt run -- plan
```

Jaeger UI (`http://localhost:16686`) で実行トレースを可視化できます。トレースのダウンロード・アップロードでチームメンバーとの共有も可能です。

## OpenTofu/Terraform の入力デバッグ

### --inputs-debug フラグ

変数の受け渡しに関する詳細情報を生成:

```bash
terragrunt run --log-level debug --inputs-debug -- plan
```

このコマンドにより:
- `terragrunt-debug.tfvars.json` ファイルが生成（OpenTofu/Terraform に渡される全変数を含む）
- 同一の呼び出しを手動で再現するための手順が表示

### デバッグワークフロー

1. デバッグコマンドを実行
2. `terragrunt-debug.tfvars.json` を確認して入力値を検証
3. デバッグファイルを使って手動で OpenTofu/Terraform を呼び出し、問題の切り分け:
   - インフラコードの設定ミス
   - Terragrunt のエラー
   - OpenTofu/Terraform のエラー

## ネイティブの OpenTofu/Terraform ログ

ツール固有の診断出力を有効化:

```bash
TF_LOG=debug terragrunt run -- plan
```

OpenTofu/Terraform のネイティブ診断出力が有効になります。
