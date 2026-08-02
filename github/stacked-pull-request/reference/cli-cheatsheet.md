# `gh stack` CLI チートシート

出典: [Stacked pull requests CLI commands — GitHub Docs](https://docs.github.com/en/pull-requests/reference/stacked-prs-cli-commands)

> [!NOTE]
> public preview 中のため、コマンド・フラグは変更される可能性があります。
> 最新は `gh stack <command> --help` で確認してください。

---

## セットアップ

```bash
gh extension install github/gh-stack     # インストール
gh extension upgrade github/gh-stack     # 更新
gh stack --help                          # サブコマンド一覧
```

**要件:** `gh` 2.90.0 以上を推奨（最低 2.0）、`git` 2.28 以上、Node.js 20 以上

---

## 日常の 5 コマンド

```bash
gh stack init <branch>     # スタックを開始
gh stack add <branch>      # 層を積む
gh stack submit            # push + PR 作成/更新 + スタックのリンク
gh stack sync              # fetch + rebase + push + PR 状態同期
gh stack merge             # マージ（引数なし = 対話ウィザードで層を選ぶ）
```

---

## スタックの管理

### `gh stack init`

```
gh stack init [flags] [branches...]
```

新しいスタックを初期化する。引数なしで対話モード（ブランチ名を尋ね、
現在のブランチを最初の層にするか選べる）。**既存ブランチを渡すと adopt され、
存在しないブランチは新規作成される。**

| フラグ                | 意味                                                   |
| --------------------- | ------------------------------------------------------ |
| `-b, --base <branch>` | trunk ブランチ。省略時はリポジトリのデフォルトブランチ |

```bash
gh stack init                                  # 対話モード
gh stack init feat/a                           # 1 層目を作成
gh stack init feat/a feat/b feat/c             # まとめて作成 / adopt
gh stack init -b release/2026-08 feat/a        # trunk を指定
```

### `gh stack add`

```
gh stack add [flags] [branch]
```

現在の HEAD に新しいブランチを作り、**スタックの最上部に追加**してチェックアウトする。
**スタックの最上層のブランチにいるときに実行する必要がある。**

| フラグ                   | 意味                                       |
| ------------------------ | ------------------------------------------ |
| `-A, --all`              | 未追跡ファイルを含むすべての変更をステージ |
| `-u, --update`           | 追跡済みファイルのみステージ               |
| `-m, --message <string>` | 新しい層を作り、**その層に**コミットを作る |

`-A` と `-u` は同時に使えない。
**`-m` を省略して `-A` / `-u` だけを渡した場合は、コミットメッセージ用のエディタが開く**（`-m` は必須ではない）。
逆に `-m` をブランチ名なしで渡すと、ブランチ名がコミットメッセージから自動生成される（`03-24-add_api_routes` 形式）。

```bash
gh stack top                                        # まず最上層へ
gh stack add feat/b
gh stack add -Am "feat: add store layer" feat/b     # ステージ+コミット+層追加
```

> [!IMPORTANT]
>
> **途中への挿入は `add` ではできない。** `gh stack modify` の
> "Insert below" / "Insert above" を使う。

### `gh stack view`

```
gh stack view [flags]
```

| フラグ        | 意味           |
| ------------- | -------------- |
| `-s, --short` | コンパクト出力 |
| `--json`      | JSON 出力      |

### `gh stack modify`

```
gh stack modify [flags]
```

現在のスタックを対話的に組み替える。**Web UI に相当機能はない。**
並べ替え・削除に加え、**"Insert below" / "Insert above"** で
スタックの途中に層を挿入できる（`add` では挿入できない）。

| フラグ       | 意味                     |
| ------------ | ------------------------ |
| `--continue` | コンフリクト解決後に続行 |
| `--abort`    | 組み替え前の状態に戻す   |

### `gh stack unstack`

```
gh stack unstack [<stack-number>] [flags]
```

スタックをローカル追跡から外し、GitHub 上でもスタックを解除する。
**PR とブランチは残る。**

| フラグ    | 意味                                              |
| --------- | ------------------------------------------------- |
| `--local` | ローカル追跡のみ削除（GitHub 上のスタックは残す） |

---

## リモート操作

### `gh stack submit`

```
gh stack submit [flags]
```

全ブランチを push → PR を作成 / 更新 → GitHub 上でスタックとしてリンク。

| フラグ            | 意味                                                                                                 |
| ----------------- | ---------------------------------------------------------------------------------------------------- |
| `--auto`          | エディタを開かず、タイトルを自動生成。**単独で使うと新規 PR は draft になる**（`--open` と併用する） |
| `--open`          | draft ではなく ready for review で作成                                                               |
| `--remote <name>` | push 先リモート                                                                                      |

### `gh stack sync`

```
gh stack sync [flags]
```

fetch → rebase → push → PR 状態同期を 1 コマンドで。**日常運用の主力。**

| フラグ            | 意味                                   |
| ----------------- | -------------------------------------- |
| `--remote <name>` | fetch / push するリモート              |
| `--prune`         | マージ済み PR のローカルブランチを削除 |

### `gh stack rebase`

```
gh stack rebase [flags] [branch]
```

リモートから pull し、スタック全体にカスケードリベースを実行する。
引数のブランチは起点（省略時は現在のブランチ）。

| フラグ                            | 意味                                          |
| --------------------------------- | --------------------------------------------- |
| `--downstack`                     | trunk から現在のブランチまで                  |
| `--upstack`                       | 現在のブランチから最上層まで                  |
| `--no-trunk`                      | trunk のリベースをスキップ                    |
| `--continue`                      | コンフリクト解決後に続行                      |
| `--abort`                         | ブランチを元の状態に戻す                      |
| `--remote <name>`                 | 対象リモート                                  |
| `--committer-date-is-author-date` | コミット日時を保持（別名 `--preserve-dates`） |

> [!WARNING]
> コンフリクト解決後は **`gh stack rebase --continue`** を使うこと。
> `git rebase --continue` だとカスケードが止まる。

### `gh stack push`

```
gh stack push [flags]
```

スタック内のアクティブなブランチをリモートに push する（PR は作らない）。

| フラグ            | 意味            |
| ----------------- | --------------- |
| `--remote <name>` | push 先リモート |

### `gh stack link`

```
gh stack link [flags] <stack-number | branch-or-pr> <branch-or-pr> [...]
```

既存の PR を GitHub 上でスタックとしてリンクする。**ローカル追跡は作らない。**
**下から順に**指定する。

| フラグ            | 意味                           |
| ----------------- | ------------------------------ |
| `--base <branch>` | スタック最下層の base ブランチ |
| `--open`          | PR を ready for review にする  |
| `--remote <name>` | 対象リモート                   |

```bash
gh stack link --base main feat/a feat/b feat/c
gh stack link --base main 12 13 14
```

### `gh stack merge`

```
gh stack merge [<stack-number> | <pr-number>] [flags]
```

> [!WARNING]
>
> **数字だけを渡すと、まずスタック番号として解決されます。**
>
> ```
> A bare number is treated first as a stack number, then as a pull request number.
> ```
>
> PR を指定したつもりでスタック全体をマージしないよう、**引数なしで実行して対話ウィザードで選ぶ**のが安全です。
> 非対話環境では `--yes` 相当になり、確認なしに全層がマージされます（[Lab 07](../labs/lab07-merge.md) 参照）。

1 つ以上のスタック PR をマージする。**指定した PR とその下の未マージ層がまとめて着地する。**

| フラグ                    | 意味                           |
| ------------------------- | ------------------------------ |
| `--merge-method <method>` | `merge` / `squash` / `rebase`  |
| `--merge`                 | `--merge-method merge` の短縮  |
| `--squash`                | `--merge-method squash` の短縮 |
| `--rebase`                | `--merge-method rebase` の短縮 |
| `-y, --yes`               | 確認プロンプトなし             |

---

## ナビゲーション

| コマンド                                                                    | 動作                                             |
| --------------------------------------------------------------------------- | ------------------------------------------------ |
| `gh stack checkout [<stack-number> \| <pr-number> \| <pr-url> \| <branch>]` | 指定した層をチェックアウト（スタック外からも可） |
| `gh stack switch`                                                           | 対話的に層を選んで移動                           |
| `gh stack up [n]`                                                           | n 層上へ（trunk から離れる方向、既定 1）         |
| `gh stack down [n]`                                                         | n 層下へ（trunk に近づく方向、既定 1）           |
| `gh stack top`                                                              | 最上層へ                                         |
| `gh stack bottom`                                                           | 最下層へ                                         |
| `gh stack trunk`                                                            | trunk へ                                         |

```bash
gh stack checkout https://github.com/OWNER/REPO/pull/42     # 他人のスタックを取り込む
```

---

## ユーティリティ

### `gh stack alias`

```
gh stack alias [flags] [name]
```

短縮エイリアスを作る。名前省略時は `gs`。

| フラグ     | 意味                     |
| ---------- | ------------------------ |
| `--remove` | 作成済みエイリアスを削除 |

```bash
gh stack alias         # gs view のように使えるようになる
gh stack alias st
gh stack alias --remove
```

### `gh stack feedback`

```
gh stack feedback [title]
```

`gh stack` 拡張へのフィードバックを送る。

---

## 終了コード

| コード | 意味                                        |
| ------ | ------------------------------------------- |
| 0      | 成功                                        |
| 1      | 一般エラー                                  |
| 2      | スタック内にいない / スタックが見つからない |
| 3      | リベースのコンフリクト                      |
| 4      | GitHub API の失敗                           |
| 5      | 引数 / フラグが不正                         |
| 6      | 曖昧な指定（disambiguation が必要）         |
| 7      | すでにリベース進行中                        |
| 8      | 他プロセスがスタックをロック中              |
| 9      | スタック PR が有効になっていない            |
| 10     | `modify` セッションが中断された             |

対処は [トラブルシューティング](troubleshooting.md) を参照。

---

## 環境変数

| 変数             | 値                        | 既定   | 意味       |
| ---------------- | ------------------------- | ------ | ---------- |
| `GH_STACK_THEME` | `auto` / `light` / `dark` | `auto` | 出力の配色 |

---

## 用語

| 用語               | 意味                                      |
| ------------------ | ----------------------------------------- |
| stack              | base が数珠つなぎになった PR の並び       |
| layer              | スタック内の 1 つの PR                    |
| trunk              | スタックが着地するブランチ（通常 `main`） |
| base               | 各 PR のターゲットブランチ                |
| bottom PR / top PR | 最下層 / 最上層の PR                      |
| stack number       | スタックの識別番号                        |

---

## 制約（public preview 時点）

- **同一リポジトリのみ**。cross-fork stack は非対応
- **線形構造のみ**。分岐したスタックは作れない
- **GitHub Desktop 非対応**
- **並べ替え（`modify`）は CLI 必須**。Web UI に相当機能なし
- 全 PR マージ後、**スタックは閉じる**（後から層を足せない）
- **merge queue に完全対応**。キュー使用時はマージ方式がキュー側の設定で上書きされる
