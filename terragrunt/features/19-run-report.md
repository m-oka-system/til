# Run Report（実行レポート）

> 公式: https://terragrunt.gruntwork.io/docs/features/run-report/

## 概要

**Run Report** は、複数ユニットの同時実行結果を追跡し、実行後のサマリーと詳細レポートを提供する機能です。

## 実行サマリー

`run --all` などのキューベース操作では、完了後に自動的にハイレベルサマリーが表示されます:

| 項目 | 説明 |
|------|------|
| Duration | 総実行時間 |
| Units | 処理されたユニット数 |
| Succeeded | 成功したユニット数 |
| Failed | 失敗したユニット数 |
| Excluded | 除外されたユニット数 |
| Early Exits | 依存関係の失敗で中断されたユニット数 |

### ユニットごとの実行時間表示

```bash
terragrunt run --all plan --summary-per-unit
```

最も時間のかかったユニットから順に、個別の実行時間を表示します。

### サマリー出力の無効化

```bash
terragrunt run --all plan --summary-disable
```

内部追跡は維持しつつ、サマリー表示を抑制します。

## 詳細レポートの生成

CSV または JSON 形式で包括的な実行レポートを出力:

```bash
# CSV 形式
terragrunt run --all plan --report-file report.csv

# JSON 形式
terragrunt run --all plan --report-file report.json --report-format json
```

ファイル拡張子からフォーマットを自動検出します。未指定の場合は CSV がデフォルトです。

### レポートのフィールド

| フィールド | 説明 |
|-----------|------|
| Name | ユニット名 |
| Started | 開始タイムスタンプ |
| Ended | 終了タイムスタンプ |
| Result | 結果カテゴリ |
| Reason | 詳細な説明 |
| Cause | 具体的な原因 |

## 結果カテゴリ

| Result | 説明 |
|--------|------|
| `Succeeded` | 正常に実行完了 |
| `Failed` | エラーが発生 |
| `Excluded` | 実行から除外 |
| `Early Exit` | 上流の依存関係失敗で中断 |

## Reason の詳細

| Result | Reason | 説明 |
|--------|--------|------|
| Succeeded | *(空文字)* | 通常の成功 |
| Succeeded | `retry succeeded` | リトライ後に復旧 |
| Succeeded | `error ignored` | 失敗が抑制された |
| Failed | `run error` | 実行エラー |
| Excluded | `exclude block` | exclude ブロックによる除外 |
| Excluded | `--queue-exclude-dir` | フラグによる除外 |
| Early Exit | `ancestor error` | 祖先ユニットのエラー |

## Cause の情報

- エラー抑制ブロック名
- 実際のエラーメッセージ
- 失敗した上流ユニット名

## JSON Schema の生成

バリデーション可能なスキーマファイルを作成:

```bash
terragrunt run --all plan --report-schema-file report.schema.json
```

JSON Schema (draft 2020-12) に準拠したスキーマが生成されます。
