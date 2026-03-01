# Provider Cache Server（プロバイダキャッシュサーバ）

> 公式: https://terragrunt.gruntwork.io/docs/features/provider-cache-server/

## 概要

**Provider Cache Server** は、全ての OpenTofu/Terraform 実行にわたってプロバイダをキャッシュする機能です。各プロバイダを1回だけダウンロードし、ローカルキャッシュサーバを運用してキャッシュを提供します。

> OpenTofu >= 1.10 の場合は、よりシンプルな [Automatic Provider Cache Dir](./16-auto-provider-cache-dir.md) も検討してください。

## キャッシュの効果

50ユニットのプロジェクトで各ユニットが AWS プロバイダ（約100MB）を使用する場合:

| 指標 | キャッシュなし | キャッシュあり |
|------|-------------|-------------|
| 帯域幅 | 5GB | 100MB |
| ディスク使用量 | 22.5GB | 450MB |

## なぜネイティブキャッシュでは不十分か

`terragrunt run --all` のように OpenTofu/Terraform プロセスを並行実行すると、ネイティブのプロバイダキャッシュは互いのキャッシュを上書きし合い、インストールエラーが発生します。Provider Cache Server はこの並行アクセスを安全に管理します。

## 有効化方法

**フラグ**:

```bash
terragrunt run --all --provider-cache apply
```

**環境変数**:

```bash
TG_PROVIDER_CACHE=1 terragrunt run --all apply
```

## キャッシュの場所

| OS | デフォルトパス |
|----|--------------|
| Unix | `$HOME/.terragrunt-cache/terragrunt/providers` |
| macOS | `$HOME/Library/Caches/terragrunt/providers` |
| Windows | `%LocalAppData%\terragrunt\providers` |

**カスタムディレクトリ**:

```bash
terragrunt plan --provider-cache --provider-cache-dir /new/path/to/cache/dir
```

**カスタムレジストリ**:

```bash
terragrunt apply --provider-cache \
  --provider-cache-registry-names example1.com \
  --provider-cache-registry-names example2.com
```

## 動作メカニズム

```
┌──────────────────┐     ┌──────────────────────┐     ┌─────────────┐
│  OpenTofu/       │────▶│  Provider Cache       │────▶│  Registry   │
│  Terraform       │     │  Server (localhost)   │     │  (upstream) │
│  Instance        │◀────│                       │◀────│             │
└──────────────────┘     └──────────────────────┘     └─────────────┘
```

1. **サーバ起動** — localhost で Provider Cache Server を起動
2. **設定** — ローカル `.terraformrc` でキャッシュサーバ経由のプロバイダ取得を強制
3. **初期化プロセス**:
   - 1回目の `init`: プロバイダを要求 → サーバがダウンロード → HTTP 423 (Locked) を返却
   - サーバが `.terraform.lock.hcl` を生成（存在しない場合）
   - 2回目の `init`: キャッシュ済みプロバイダを検出 → シンボリックリンクを即座に作成

## ユーザーディレクトリからの再利用

キャッシュサーバはまずユーザーのプラグインディレクトリからシンボリックリンクを試みます:

| OS | プラグインディレクトリ |
|----|---------------------|
| Windows | `%APPDATA%\terraform.d\plugins` |
| その他 | `~/.terraform.d/plugins` |

## 詳細設定

| フラグ | デフォルト | 用途 |
|--------|----------|------|
| `--provider-cache-hostname` | `localhost` | サーバアドレス |
| `--provider-cache-port` | ランダム | サーバポート |
| `--provider-cache-token` | ランダム | 認証トークン |

```bash
terragrunt apply --provider-cache \
  --provider-cache-host 192.168.0.100 \
  --provider-cache-port 5758 \
  --provider-cache-token my-secret
```

環境変数: `TG_PROVIDER_CACHE_HOST`, `TG_PROVIDER_CACHE_PORT`, `TG_PROVIDER_CACHE_TOKEN`

## マルチプラットフォームのロックファイル生成

```bash
terragrunt run --provider-cache -- providers lock \
  -platform=linux_amd64 \
  -platform=darwin_arm64 \
  -platform=freebsd_amd64
```
