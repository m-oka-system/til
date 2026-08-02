# Lab 04: 下層の修正を上へ伝播させる

所要 30 分 | 使うコマンド: `rebase` / `sync` / `submit`

---

## ゴール

スタック運用で**最も頻度が高い操作**を身につける。
「下層にレビュー指摘が入った → 直す → 上層すべてに反映する」を手作業なしで回す。

## 開始状態

[Lab 03](lab03-review.md) 完了。3 層のスタックが GitHub 上にあり、PR #1 にレビューコメントが付いている。

```bash
cd "${PLAYGROUND_DIR:-$HOME/stacked-pr-playground}" && gh stack view
```

---

## Step 1: 下層にレビュー指摘を反映する

[Lab 03](lab03-review.md) で PR #1 に「title の長さ上限チェックも必要では？」というコメントが付きました。
これに対応します。

```bash
gh stack bottom          # feat/task-model へ
```

`src/model.js` の `validateTask` に上限チェックを追加します。

```bash
cat > src/model.js <<'EOF'
const VALID_STATUSES = ['todo', 'doing', 'done'];
const MAX_TITLE_LENGTH = 120;

export function createTask({ id, title, status = 'todo' }) {
  const task = { id, title, status };
  const errors = validateTask(task);
  if (errors.length > 0) {
    throw new Error(`invalid task: ${errors.join(', ')}`);
  }
  return task;
}

export function validateTask(task) {
  const errors = [];
  if (!task.id) errors.push('id is required');
  if (!task.title || task.title.trim() === '') errors.push('title is required');
  if (task.title && task.title.length > MAX_TITLE_LENGTH) {
    errors.push(`title must be ${MAX_TITLE_LENGTH} characters or less`);
  }
  if (!VALID_STATUSES.includes(task.status)) errors.push(`status must be one of ${VALID_STATUSES.join('|')}`);
  return errors;
}

export { VALID_STATUSES, MAX_TITLE_LENGTH };
EOF

git add src/model.js
git commit -m "feat(model): enforce max title length"
```

---

## Step 2: 上層が古くなったことを確認する

いま `feat/task-store` と `feat/task-api` は、**修正前の** `feat/task-model` の上に乗っています。

```bash
gh stack view
```

上層が古い旨のマーカーが表示されるはずです。
生の git でも確認できます。

```bash
git log --oneline feat/task-model
git merge-base --is-ancestor feat/task-model feat/task-store && echo "up to date" || echo "STALE"
# → STALE
```

ここで何もしないと、PR #2 のレビュアーは
「まだ長さチェックが入っていない `model.js`」を前提に読むことになり、話が食い違います。

---

## Step 3: カスケードリベースで上層に伝播させる

```bash
gh stack rebase
```

これで `feat/task-model` の変更が `feat/task-store` → `feat/task-api` と順に取り込まれます。

確認:

```bash
git merge-base --is-ancestor feat/task-model feat/task-store && echo "up to date"
git merge-base --is-ancestor feat/task-store feat/task-api && echo "up to date"
```

### `rebase` のフラグ

| フラグ                            | 意味                                          | 使いどころ                         |
| --------------------------------- | --------------------------------------------- | ---------------------------------- |
| `--downstack`                     | trunk から現在のブランチまでをリベース        | 下側だけ更新したい                 |
| `--upstack`                       | 現在のブランチから最上層までをリベース        | 自分の層より上だけ更新したい       |
| `--no-trunk`                      | trunk のリベースをスキップ                    | trunk の最新を取り込みたくないとき |
| `--continue`                      | コンフリクト解決後に続行                      | [Lab 05](lab05-conflict.md) で扱う |
| `--abort`                         | 中断して元の状態に戻す                        | [Lab 05](lab05-conflict.md) で扱う |
| `--committer-date-is-author-date` | コミット日時を保持（別名 `--preserve-dates`） | 履歴の日付を保ちたいとき           |
| `--remote <name>`                 | fetch / push 先のリモート                     | 複数リモート運用時                 |

引数にブランチ名を渡すと、そのブランチを起点にできます（省略時は現在のブランチ）。

```bash
gh stack rebase --upstack feat/task-store    # store 以上だけリベース
```

---

## Step 4: GitHub 側に反映する

ローカルでリベースしただけでは PR は古いままです。

```bash
gh stack submit
```

または push だけでよければ:

```bash
gh stack push
```

PR ページを見て、PR #2 の base が最新の `feat/task-model` を指していること、
差分に `model.js` が混ざっていないことを確認します。

```bash
gh stack up
gh pr view --web
```

---

## Step 5: `sync` で一括処理する（実務のメインルート）

Step 2〜4 でやったことは、実は 1 コマンドにまとまっています
（Step 1 のソース編集とコミットは別途必要です）。

```bash
gh stack sync
```

`sync` は次を順に実行します。

1. **fetch** — リモートの最新を取得
2. **rebase** — trunk の変更を取り込みながらカスケードリベース
3. **push** — 全ブランチを push
4. **PR 状態の同期** — GitHub 上の PR / スタック情報を更新

| フラグ            | 意味                                   |
| ----------------- | -------------------------------------- |
| `--remote <name>` | fetch / push するリモート              |
| `--prune`         | マージ済み PR のローカルブランチを削除 |

### `--prune` を試す

いまはまだマージ済み PR がないので効果は見えませんが、
[Lab 07](lab07-merge.md) でマージした後にこれを打つと、不要になったローカルブランチが片付きます。

```bash
gh stack sync --prune
```

> [!TIP]
>
> **朝イチで `gh stack sync` を打つ**のを習慣にしてください。
> `main` が進んでいれば取り込まれ、他人がマージした層があれば反映され、
> ローカルと GitHub のズレがリセットされます。

---

## Step 6: trunk が進んだ状況を作って sync する

`main` が進んだ状態を再現します。GitHub 上で `main` に直接コミットを足します。

```bash
gh stack trunk && git pull    # スタックを離れて trunk へ

echo "" >> README.md
echo "## Notes" >> README.md
echo "- playground for stacked PR training" >> README.md
# trunk にいることを確かめてから push する（層にいたまま実行すると誤った PR にコミットが入る）
[ "$(git branch --show-current)" = "main" ] \
  && git add README.md \
  && git commit -m "docs: add notes section" \
  && git push origin main
```

スタックに戻って sync します。

```bash
gh stack bottom
gh stack sync
```

`main` の新しいコミットが、スタックの全層に取り込まれたことを確認します。

```bash
git log --oneline feat/task-api | head -6
gh stack view
```

---

## 確認ポイント

- [ ] 下層のコミット後、上層が STALE になることを確認した
- [ ] `gh stack rebase` で全層に伝播した
- [ ] `gh stack submit` / `push` で GitHub 側に反映した
- [ ] `gh stack sync` が fetch → rebase → push → 同期をまとめて行うことを理解した
- [ ] trunk が進んだ状態から `sync` で追随できた

---

## つまずきポイント

| 症状                                                | 原因と対処                                                                                   |
| --------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `rebase` が exit 3（Rebase conflict）で止まる       | コンフリクト。[Lab 05](lab05-conflict.md) の手順で解決する                                   |
| `rebase` が exit 7（Rebase already in progress）    | 前回のリベースが未完了。`gh stack rebase --continue` か `--abort`                            |
| `sync` 後も PR が古い                               | ネットワークエラーで push が失敗している可能性。`gh stack push` を単独で実行して確認         |
| `sync` が exit 8（Stack locked by another process） | 別の `gh stack` プロセスが動いている。終了を待つ                                             |
| リベース後に force push が必要と言われる            | `gh stack push` は必要に応じて force-with-lease 相当の処理をする。生の `git push` を使わない |

> [!WARNING]
> スタックのブランチに対して**生の `git push --force` を使わない**でください。
> `gh stack push` / `submit` / `sync` を経由すれば、追跡情報と PR の整合性が保たれます。

---

## 振り返り課題

1. `gh stack rebase` と `gh stack sync` の違いを説明せよ。
2. `--downstack` と `--upstack` はそれぞれどんな場面で使うか。
3. 5 層のスタックで、3 層目にレビュー指摘が入った。最小の手数で全体を最新化するコマンドは。
4. なぜ生の `git push --force` を避けるべきか。

<details>
<summary>解答</summary>

1. `rebase` はリモートからの pull とカスケードリベースまで。push や PR 状態の同期はしない。
   `sync` はそれに加えて push と PR 状態同期までを一括で行う。
   なお `rebase` も trunk を取りにリモートへ触れるため、**完全なローカル完結ではない**
   （リモートに触れずに層どうしだけ揃えたい場合は `--no-trunk`）。
2. `--downstack`: 自分の層より下だけを最新化したい（trunk の変更を自分の層まで取り込む）。
   `--upstack`: 自分の層を直したので、上の層だけに伝播させたい。全層を触りたくないとき。
3. 3 層目で修正をコミットしたあと `gh stack sync`（または `gh stack rebase --upstack` → `gh stack submit`）。
4. `gh stack` が保持する追跡情報と GitHub 上のスタック状態が食い違い、
   base の再ターゲットや差分表示が壊れる可能性があるため。

</details>

---

次は [Lab 05: コンフリクトを解決する](lab05-conflict.md) へ。
