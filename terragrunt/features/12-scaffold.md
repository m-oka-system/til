# Scaffold（スキャフォールド）

> 公式: https://terragrunt.gruntwork.io/docs/features/scaffold/

## 概要

**Scaffold** は、ボイラープレートテンプレートを使ってファイルを自動生成する機能です。主な用途は、ベストプラクティスに基づく `terragrunt.hcl` ファイルの作成です。

## 基本コマンド

```bash
terragrunt scaffold <MODULE_URL> [TEMPLATE_URL] [--var] [--var-file] \
  [--no-include-root] [--root-file-name] [--no-dependency-prompt]
```

| パラメータ | 説明 |
|-----------|------|
| `MODULE_URL` | OpenTofu/Terraform モジュールの場所（ローカルパス、Git URL、レジストリ URL） |
| `TEMPLATE_URL` | カスタムテンプレートの場所（省略可） |

## デフォルト動作

テンプレート未指定時の処理順序:

1. 対象モジュール内の `.boilerplate` ディレクトリを検索
2. 見つからなければ組み込みのデフォルトテンプレートを使用

生成される設定には以下が含まれます:
- 最新リリースタグを `ref` に設定した `source` URL
- 全ての必須・任意変数の `inputs` セクション（型・説明・デフォルト値付き）

## テンプレート変数

テンプレートで利用可能な自動公開変数:

| 変数 | 説明 |
|------|------|
| `sourceUrl` | モジュール URL |
| `requiredVariables` | 必須入力変数（Name, Description, Type, DefaultValue） |
| `optionalVariables` | 任意入力変数（同上） |

カスタマイズ可能な変数:

| 変数 | 説明 | デフォルト |
|------|------|----------|
| `Ref` | Git タグまたはブランチ | 最新タグ |
| `EnableRootInclude` | ルート terragrunt.hcl の include | `true` |
| `RootFileName` | ルート設定ファイル名 | `terragrunt.hcl` |
| `SourceUrlType` | `git-ssh` 形式への変換 | — |
| `SourceGitSshUser` | SSH 用の Git ユーザー | `git` |

## 使用例

### 基本的なスキャフォールディング

```bash
terragrunt scaffold github.com/gruntwork-io/terragrunt-infrastructure-modules-example//modules/mysql
```

### 特定バージョンの指定

```bash
terragrunt scaffold github.com/gruntwork-io/terragrunt.git//test/fixtures/inputs \
  --var=Ref=v0.68.4
```

### Git/SSH URL の使用

```bash
terragrunt scaffold github.com/gruntwork-io/terragrunt.git//test/fixtures/inputs \
  --var=SourceUrlType=git-ssh
```

### 外部テンプレートの使用

```bash
terragrunt scaffold \
  github.com/gruntwork-io/terragrunt.git//test/fixtures/inputs \
  git@github.com:gruntwork-io/terragrunt.git//test/fixtures/scaffold/external-template
```

## コンビニエンスフラグ

| フラグ | 説明 |
|--------|------|
| `--no-include-root` | 生成ファイルにルート設定の include を無効化 |
| `--root-file-name` | カスタムルート設定ファイル名を設定 |
| `--no-dependency-prompt` | 依存関係の確認プロンプトをスキップ |

## セキュリティに関する注意

外部リポジトリからインフラをスキャフォールドする場合、セキュリティや安定性のリスクが伴う可能性があります。信頼できるソースのコードのみを使用し、実行前に必ずレビューしてください。
