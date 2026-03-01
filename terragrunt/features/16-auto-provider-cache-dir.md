# Automatic Provider Cache Dir（自動プロバイダキャッシュディレクトリ）

> 公式: https://terragrunt.gruntwork.io/docs/features/auto-provider-cache-dir/

## 概要

**Automatic Provider Cache Dir** は、`TF_PLUGIN_CACHE_DIR` 環境変数を自動設定することで、手動設定なしで効率的なプロバイダキャッシュを実現する機能です。

## 要件

| 要件 | 詳細 |
|------|------|
| OpenTofu バージョン | **1.10 以上**が必須 |
| 対応 IaC | OpenTofu のみ（Terraform は非対応） |

要件を満たさない場合、機能はサイレントに無効化されます。

## 動作の仕組み

有効時に Terragrunt が自動的に行う処理:

1. OpenTofu が最低バージョン要件を満たすか検証
2. デフォルトの場所にプロバイダキャッシュディレクトリを作成
3. `TF_PLUGIN_CACHE_DIR` 環境変数を設定
4. 適切な権限でキャッシュディレクトリを作成

### デフォルトのキャッシュ場所

| OS | パス |
|----|------|
| Unix | `$HOME/.terragrunt-cache/providers` |
| macOS | `$HOME/Library/Caches/terragrunt/providers` |
| Windows | `%LocalAppData%\terragrunt\providers` |

## メリット

- **パフォーマンス向上** — プロバイダを1回ダウンロードして再利用
- **帯域幅削減** — 冗長なダウンロードの排除
- **並行性の改善** — OpenTofu 1.10+ が安全な並行キャッシュアクセスを処理

## 設定オプション

### カスタムキャッシュディレクトリ

```bash
terragrunt apply --provider-cache-dir /custom/path/to/cache
```

### 環境変数

```bash
TG_PROVIDER_CACHE_DIR='/custom/path/to/cache' terragrunt apply
```

### 機能の無効化

```bash
terragrunt run --all apply --no-auto-provider-cache-dir
```

## Provider Cache Server との比較

| 観点 | Auto Provider Cache Dir | Provider Cache Server |
|------|------------------------|-----------------------|
| セットアップ | シンプル、低メンテナンス | やや複雑 |
| 要件 | OpenTofu >= 1.10 | バージョン制限なし |
| メカニズム | ネイティブ OpenTofu 機構 | Terragrunt 独自サーバ |
| 用途 | 基本的なキャッシュ | 高度な機能、クロスファイルシステム共有 |

## トラブルシューティング

- OpenTofu バージョンの確認: `tofu version`
- キャッシュディレクトリのアクセス可能性を確認
- デバッグログの有効化: `--log-level debug`
