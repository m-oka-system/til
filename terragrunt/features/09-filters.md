# Filters（フィルタ）

> 公式: https://terragrunt.gruntwork.io/docs/features/filter/

## 概要

**Filters** は、`--filter` フラグを使って柔軟なクエリ言語で特定のユニットやスタックをターゲティングする機能です。従来の `--queue-include-dir` / `--queue-exclude-dir` を統一的に置き換えます。

## フィルタ式の種類

| 式の種類 | 説明 | 例 |
|---------|------|-----|
| **Name** | 名前でユニット/スタックを識別 | `name=web` |
| **Path** | ファイルシステム上の位置で対象を指定 | `./prod/**` |
| **Attribute** | 設定プロパティでマッチ | `type=stack` |
| **Negated** | `!` プレフィックスで除外 | `!./subtree/**` |
| **Intersection** | `\|` 演算子で結果を絞り込み | `'./prod/** \| name=web'` |
| **Union** | 複数の `--filter` フラグで結合 | `--filter A --filter B` |
| **Graph** | 依存関係を辿る | — |
| **Git** | Git diff に基づくフィルタ | — |

## 使用例

### パスとの名前の交差

```bash
terragrunt find --filter './prod/** | name=web'
```

`prod/services/web` のみが返されます（パスと名前の両方にマッチ）。

### 複数フィルタの組み合わせ

```bash
terragrunt run --all --filter './subtree/**' --filter '!./subtree/dependency/**' -- plan
```

## 対応コマンド

`--filter` は以下のコマンドで使用できます:

- `find`
- `list`
- `run`
- `hcl fmt`
- `hcl validate`
- `stack run`
- `stack generate`

## レガシーフラグとの対応

| 旧フラグ | 新しい `--filter` |
|---------|-------------------|
| `--queue-include-dir=./path` | `--filter='./path'` |
| `--queue-exclude-dir=./path` | `--filter='!./path'` |

## 特殊な考慮事項

### hcl fmt

パスベースの式のみ有効です（ファイル単位での操作のため）。

### stack generate

意図しない適用を防ぐため、スタックを明示的にターゲット（例: `type=stack`）する必要があります。
