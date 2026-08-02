# トラブルシューティング

---

## まず打つコマンド

状態が分からなくなったら、この 4 つで現在地を確認します。

```bash
gh stack view              # スタックの構造と現在地
git status                 # リベース進行中か、未コミットの変更があるか
git branch --show-current  # 今どのブランチにいるか
gh stack view; echo "exit=$?"   # 終了コードで状況を特定
```

---

## 終了コード別の対処

### exit 1 — 一般エラー

メッセージを読むのが最短です。それでも分からない場合:

```bash
gh extension upgrade github/gh-stack     # 拡張が古い可能性
gh --version                             # 2.90.0 以上か（最低 2.0）
git --version                            # 2.28 以上か
```

### exit 2 — スタック内にいない / スタックが見つからない

**原因の候補:**

- まだ `gh stack init` していない
- trunk にいて、どのスタックにも属していない
- 別のリポジトリにいる
- ローカル追跡が消えている（`link` だけしてローカル追跡を作っていない等）

**対処:**

```bash
gh stack init <branch>                # 新規に始める
gh stack checkout <PR番号 or ブランチ>  # 既存スタックに入る
gh stack init <既存ブランチ...>          # 既存ブランチを adopt
```

### exit 3 — リベースのコンフリクト

正常なフローの一部です。解決して続行します。

```bash
git status                     # コンフリクトしているファイルを確認
# ファイルを編集して解決
git add <解決したファイル>
gh stack rebase --continue     # ← git rebase --continue ではない
```

引き返す場合:

```bash
gh stack rebase --abort
```

詳しくは [Lab 05](../labs/lab05-conflict.md)。

### exit 4 — GitHub API の失敗

**原因の候補:**

- 認証切れ / スコープ不足
- レート制限
- 一時的な障害

**対処:**

```bash
gh auth status
gh auth refresh -s repo
gh api rate_limit --jq '.rate'    # 残り回数を確認
```

GitHub の稼働状況: https://www.githubstatus.com/

### exit 5 — 引数 / フラグが不正

```bash
gh stack <command> --help
```

よくある間違い:

- `gh stack add -A -u` を同時指定（排他）
- `gh stack link` の引数を上から順に並べた（**下から順**が正しい）

### `gh stack add` が「最上層で実行せよ」と言われる

`gh stack add` は**スタックの最上層のブランチにいるとき**にしか実行できません。

```bash
gh stack top
gh stack add <branch>
```

**途中に層を挿入したい場合は `add` では実現できません。**
`gh stack modify` の "Insert below" / "Insert above" を使ってください。

### exit 6 — 曖昧な指定（disambiguation required）

同名のブランチが複数のスタックに存在する、などのケース。
**より具体的な指定**に切り替えます。

```bash
gh stack checkout https://github.com/OWNER/REPO/pull/42  # URL。最も曖昧さがない
gh stack checkout feat/task-store                        # ブランチ名（ローカル追跡がある場合）
gh stack view --json                                     # stack number を確認してから指定

# 数字だけを渡すと「まず stack number」として解決される点に注意
# （曖昧さを解消したい場面で曖昧な指定を使わない）
gh stack checkout 42
```

### exit 7 — すでにリベース進行中

前回のリベースが決着していません。**どちらかを選んで終わらせます。**

```bash
gh stack rebase --continue      # 解決済みなら続行
gh stack rebase --abort         # 中断して元に戻す
```

git 側にも中途半端なリベースが残っている場合:

```bash
git status                      # "rebase in progress" かを確認
git rebase --abort              # 最後の手段。この後 gh stack view で状態を確認
```

### exit 8 — 他プロセスがスタックをロック中

別のターミナルやエディタの統合ターミナルで `gh stack` が動いています。

**対処:**

1. 他のターミナルを確認し、動いているコマンドの終了を待つ
2. プロセスが残っていないか確認する

```bash
ps aux | grep 'gh-stack\|gh stack' | grep -v grep
```

3. 明らかにゾンビプロセスなら終了させてから再実行

### exit 9 — スタック PR が有効になっていない

**原因:** そのリポジトリまたは organization でスタック機能が使えません。

**確認すること:**

- public preview のロールアウトが対象リポジトリに到達しているか
- organization / enterprise の設定でプレビュー機能が制限されていないか
- リポジトリへの書き込み権限があるか

```bash
gh repo view --json nameWithOwner,viewerPermission
gh auth status
```

**対処:** 本教材の `bootstrap-playground.sh` は既定で個人アカウントに新しいリポジトリを作るので、
**そこで exit 9 が出た時点で「個人アカウントで試す」という切り分けは済んでいます。**

- **練習用リポジトリ（個人アカウント）で exit 9**
  → スタック機能がそのアカウントにまだ展開されていません。public preview は
  順次ロールアウト中のため、待つ以外にできることはありません。
  [公式の状況](https://github.blog/changelog/2026-07-30-stacked-pull-requests-are-now-in-public-preview/) を確認してください。
  **この状態では Lab 01 以降を実施できません。**（`docs/01-setup.md` のチェックリストで
  先に弾かれるはずですが、途中から出た場合も同じです）
- **業務リポジトリ（organization）でのみ exit 9**
  → organization 側の設定です。管理者に有効化を依頼してください。

### exit 10 — `modify` セッションが中断された

`gh stack modify` の途中でターミナルが閉じた等。**決着をつけてから他の操作をします。**

```bash
gh stack modify --continue      # 続行
gh stack modify --abort         # 組み替え前に戻す
```

---

## 症状別

### PR の差分に下層の変更が混ざる

**原因:** base が正しくない、または上層で下層の変更を再適用した。

```bash
gh pr list --json number,headRefName,baseRefName \
  --jq '.[] | "\(.number)\t\(.headRefName)\t→ \(.baseRefName)"'
```

base の連鎖が切れていたら:

```bash
gh stack sync           # リベースし直して push
gh stack submit         # PR とスタックのリンクを更新
```

コンフリクト解決で下層の変更を再適用してしまった場合、**リベースがまだ進行中なら**
該当層で `gh stack rebase --abort` してやり直せます。

**すでにリベースが完走している場合は `--abort` は使えません**（戻す対象のセッションがないため）。
その場合は該当層で修正コミットを積むか、`git reset --hard <リベース前の SHA>` で層を戻してから
`gh stack rebase` をやり直します（SHA は `git reflog` で拾えます）。

### stack map が表示されない

その PR が GitHub 上でスタックとしてリンクされていません。

```bash
gh stack submit                                    # 自分のスタックなら
gh stack link --base main <下> <中> <上>            # 既存 PR をリンクする場合
```

### ローカルで直したのに PR が更新されない

`push` / `submit` していません。

```bash
gh stack submit
# または
gh stack sync
```

### PR は更新されたのにローカルが古い

```bash
gh stack sync
```

### `git push --force` を使ってしまった

追跡情報と GitHub 上のスタックがずれた可能性があります。

```bash
gh stack sync           # まず同期を試す
gh stack view           # 構造が壊れていないか確認
```

直らない場合は、ローカル追跡を作り直します（PR は残ります）。

```bash
gh stack unstack --local
gh stack init --base main <ブランチを下から順に...>
gh stack submit
```

### `git rebase --continue` を使ってしまった

その層で止まり、上の層にカスケードされていません。

```bash
gh stack rebase         # 残りの層を処理し直す
gh stack submit
```

### マージがブロックされる

**原因の候補（下ほど見落としやすい）:**

1. その層自身が必須レビュー / 必須チェックを満たしていない
2. **その下の層**が要件を満たしていない
3. コンフリクトがある
4. merge queue 待ち

```bash
gh stack view            # 各層のレビュー / チェック状態を確認
gh pr checks             # 現在の層のチェック詳細
```

**下から順に**要件を満たしていく必要があります。

### 中間層で CI が走らない

ワークフローの `on` 条件を確認します。

- `paths` フィルタでその層のファイルが対象外になっていないか
- `on: pull_request` そのものが定義されているか

なお `branches: [main]` フィルタは、スタック内の全 PR で発火します
（[Lab 09](../labs/lab09-ci-protection.md) 参照）。

### `github.event.pull_request.stack` が `null`

その PR がスタックに属していません。

```bash
gh stack view
gh pr view <番号> --json number,title
```

通常の PR では `null` になるのが正しい挙動です（後方互換のため）。

### ローカルにマージ済みブランチが溜まる

```bash
gh stack sync --prune
```

### 対話コマンド（`modify` / `switch`）が意図しないエディタで開く

```bash
export EDITOR=vim        # または好みのエディタ
git config --global core.editor "code --wait"    # VS Code の例
```

### 出力の色が読みにくい

```bash
export GH_STACK_THEME=dark     # auto | light | dark
```

---

## 最後の手段: スタックを作り直す

**PR とブランチは残したまま**、追跡情報だけ作り直す手順です。

```bash
# 1. 現状のブランチと PR の対応を控える
gh pr list --json number,headRefName,baseRefName \
  --jq '.[] | "\(.number)\t\(.headRefName)\t→ \(.baseRefName)"'

# 2. ローカル追跡を外す
gh stack unstack --local

# 3. 既存ブランチを adopt して作り直す（下から順に）
gh stack init --base main feat/a feat/b feat/c

# 4. GitHub 側に反映
gh stack submit
gh stack view
```

それでも直らない場合は、演習環境なら作り直すのが速いです。

**このカリキュラムのディレクトリ（`github/stacked-pull-request/`）に移動してから**実行します。
練習用リポジトリの中から相対パスで呼ぶと見つかりません。

```bash
cd "${SPR_HOME:?先にカリキュラムのディレクトリで SPR_HOME を export してください}" \
  && ./scripts/reset-playground.sh \
  && ./scripts/bootstrap-playground.sh
```

---

## 情報源

- `gh stack <command> --help` — 最も正確
- [CLI コマンドリファレンス — GitHub Docs](https://docs.github.com/en/pull-requests/reference/stacked-prs-cli-commands)
- `gh stack feedback` — 拡張へのフィードバック / 不具合報告
- [GitHub Status](https://www.githubstatus.com/) — 障害の確認
