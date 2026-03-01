# Catalog（カタログ）

> 公式: https://terragrunt.gruntwork.io/docs/features/catalog/

## 概要

**Catalog** は、モジュールカタログを検索・管理するためのインタラクティブな UI を提供する機能です。Terraform/OpenTofu モジュールの発見、探索、スキャフォールディングを支援します。

## 基本コマンド

```bash
terragrunt catalog <repo-url> [--no-include-root] [--root-file-name]
```

## リポジトリの検出優先順位

1. `<repo-url>` 引数が指定された場合、そのリポジトリを一時ディレクトリにクローン
2. URL なしの場合、`terragrunt.hcl` ファイル内のリポジトリ設定を検索（親ディレクトリも走査）
3. 設定がない場合、カレントディレクトリのモジュールをスキャン

## terragrunt.hcl での設定

```hcl
catalog {
  default_template = "git@github.com/acme/example.git//path/to/template"
  urls = [
    "relative/path/to/repo",
    "/absolute/path/to/repo",
    "github.com/gruntwork-io/terraform-aws-lambda",
  ]
  no_shell = true
  no_hooks = true
}
```

## インタラクティブ操作

カタログが起動すると、検索可能なテーブルにモジュールが表示されます:

| キー | 操作 |
|------|------|
| `/` | フィルタリング開始 |
| 矢印キー | エントリの移動 |
| `Enter` | モジュール詳細の表示 |
| `S` | スキャフォールド機能の使用 |

## セキュリティ設定

テンプレート実行の安全性を制御する2つのオプション:

| オプション | 説明 |
|-----------|------|
| `no_shell` | テンプレート内のシェルコマンド実行を防止 |
| `no_hooks` | テンプレート内のフック実行を無効化 |

**CLI フラグでの指定**:

```bash
terragrunt catalog --no-shell --no-hooks
terragrunt scaffold module-url --no-shell
```

優先順位: CLI フラグ > catalog 設定 > デフォルト（両方とも許可）

## カスタムテンプレート

コード生成のカスタマイズ方法:

1. Terraform/OpenTofu モジュール内に `.boilerplate` サブディレクトリを配置
2. catalog 設定で `default_template` パスを指定
