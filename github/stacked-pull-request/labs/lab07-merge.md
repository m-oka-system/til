# Lab 07: マージ戦略を選ぶ

所要 40 分 | 使うコマンド: `merge` / `sync --prune` / `unstack`

---

## ゴール

スタックの着地パターンを 3 つとも体験する。
「部分マージ → 自動再ターゲット」というスタック最大の利点を目で確認する。

## 開始状態

[Lab 06](lab06-modify.md) 完了。次の構造のスタックが GitHub 上にある。

```
feat/task-api
feat/task-store
feat/task-errors
feat/task-model
docs/setup-guide
main
```

```bash
cd "${PLAYGROUND_DIR:-$HOME/stacked-pr-playground}" && gh stack sync && gh stack view
```

> [!NOTE]
> Lab 06 で `feat/task-errors` を挿入していない場合は 4 層構成になります。手順は同じです。

---

## マージの 3 パターン

| パターン       | やること                                                     | 使いどころ                                   |
| -------------- | ------------------------------------------------------------ | -------------------------------------------- |
| **部分マージ** | 承認済みの下層だけマージ。上層は自動で再ターゲット           | レビュー速度が層ごとに違うとき。最も多い     |
| **一括マージ** | 準備できた最上位の PR をマージ。下の未マージ層もまとめて着地 | 全層の承認が揃ったとき                       |
| **段階マージ** | 下から 1 層ずつ順に                                          | 各層のデプロイ影響を確認しながら進めたいとき |

**共通ルール: マージは常に下から上へ。** 上層を先にマージすることはできません。

---

## Step 1: 部分マージ — 最下層だけマージする

`docs/setup-guide` は依存がないので先に着地させます。

まず現状の base を控えておきます。

```bash
gh stack view
gh pr list --json number,title,baseRefName,headRefName --jq '.[] | "\(.number)\t\(.headRefName)\t→ \(.baseRefName)"'
```

出力例:

```
3	feat/task-api	→ feat/task-store
2	feat/task-store	→ feat/task-errors
5	feat/task-errors	→ feat/task-model
1	feat/task-model	→ docs/setup-guide
4	docs/setup-guide	→ main
```

> [!NOTE]
>
> **PR 番号は作成順に振られるので、スタックの順序とは一致しません。**
> Lab 01 で #1〜#3、Lab 06 で #4（`docs/setup-guide`）と #5（`feat/task-errors`）が作られたため、
> 最下層の `docs/setup-guide` が #4 になっています。
> **番号の若い順ではなく、常に「下から」マージします。**

最下層をマージします。

```bash
gh stack bottom
gh stack merge --squash     # 引数なし = 現在のスタック。ウィザードで最下層までを選ぶ
```

> [!WARNING]
>
> **数字を直接渡すときは注意してください。** 引数は `[<stack-number> | <pr-number>]` で、
> **数字だけを渡すと先にスタック番号として解釈されます。**
>
> ```
> A bare number is treated first as a stack number, then as a pull request number.
> （gh stack merge --help）
> ```
>
> つまり `gh stack merge 1` は「PR #1」ではなく「**スタック 1 全体**」を指しうるため、
> 1 層だけ着地させるつもりでスタックごとマージしてしまう危険があります。
> **数字は渡さず、引数なしで `gh stack merge` を実行し、ウィザードで層を選ぶのが安全です。**
> スタックの外から特定のスタックを指定したいときだけ stack number を使ってください。

### `gh stack merge` の指定方法とフラグ

```
gh stack merge [<stack-number> | <pr-number>] [flags]
```

| フラグ                    | 意味                                 |
| ------------------------- | ------------------------------------ |
| `--merge-method <method>` | `merge` / `squash` / `rebase` を指定 |
| `--merge`                 | `--merge-method merge` の短縮        |
| `--squash`                | `--merge-method squash` の短縮       |
| `--rebase`                | `--merge-method rebase` の短縮       |
| `-y, --yes`               | 確認プロンプトなしでマージ           |

### 対話ウィザードの使い方

引数なしで実行すると対話ウィザードが開きます。3 段構成です。

1. **どこまでマージするか** — スタックの層が一覧で並びます。カーソルで選んで確定します。
   **選んだ層より下はすべて含まれます。** 部分マージはこの仕組みで行います
2. **マージ方式** — `--squash` のようにコマンドラインで指定済みの場合、この段は表示されないことがあります
3. **確認** — 実行前の最終確認

Step 1 では**最下層**（`docs/setup-guide`）を、Step 4 では **`feat/task-store`** を選びます。
選択を誤ると意図より上まで着地し、以降の Step が成立しなくなります。**確定する前に選択位置を必ず確認してください。**

> [!WARNING]
>
> **TTY のない環境ではウィザードが出ません。** VS Code のタスク、スクリプト経由、
> AI エージェント経由などで実行すると、**`--yes` を付けたのと同じ扱いになります。**
>
> ```
> In a non-interactive terminal, or with --yes, the whole stack
> (or everything up to the given PR) is merged without prompting.
> （gh stack merge --help）
> ```
>
> つまり引数なしで実行すると、**確認なしにスタック全体がマージされます。不可逆です。**
> この Lab は必ず対話ターミナルで実行してください。

---

## Step 2: 自動再ターゲットを確認する

**ここがスタック PR の核心です。**

```bash
gh pr list --json number,title,baseRefName,headRefName --jq '.[] | "\(.number)\t\(.headRefName)\t→ \(.baseRefName)"'
```

`feat/task-model` の PR の base が、`docs/setup-guide` から **`main` に自動で付け替わっている**はずです。

```
3	feat/task-api	→ feat/task-store
2	feat/task-store	→ feat/task-errors
5	feat/task-errors	→ feat/task-model
1	feat/task-model	→ main          ← 自動で再ターゲットされた
```

> [!NOTE]
>
> **base の張り替えそのものは、従来の GitHub でも自動でした。**
> マージ済みブランチが削除されると、それを base にしていた open な PR は自動でマージ先へ張り替えられます
> （[Pull Request Retargeting](https://github.blog/changelog/2020-05-19-pull-request-retargeting/)、2020 年〜）。
>
> 手動運用で壊れるのはその先です。**squash / rebase マージを選ぶと** trunk に入るコミットは
> 元コミットと別 SHA になるため、張り替え後の三点差分の起点が下層の分岐前まで戻り、
> `feat/task-model` の変更が上層の PR に**二重に**現れます。rebase すれば同じ変更が二重適用されてコンフリクトします。
>
> `gh stack` はこれを検知して `git rebase --onto` でマージ済みコミットを飛ばして replay します
> （次の Step の `gh stack sync` がそれです）。ここが手動運用との実質的な差です。

ブラウザでも確認します。

```bash
gh stack bottom
gh pr view --web
```

stack map から `docs/setup-guide` が消え、残りの層が繰り上がっています。

---

## Step 3: ローカルを追随させる

```bash
gh stack sync --prune
```

- リモートの `main` にマージ結果が取り込まれ、全層がリベースされる
- `--prune` により、マージ済み PR のローカルブランチ（`docs/setup-guide`）が削除される

```bash
git branch | grep setup-guide     # 何も出ない
gh stack view                     # マージ済みの層は merged として残る
```

> [!NOTE]
>
> `--prune` が削除するのは**ローカルブランチだけ**です。スタックのメタデータは保持されるので、
> マージ済みの層が `gh stack view` から消えるわけではありません。
>
> ```
> Stack metadata is preserved so that rebase and display logic continue to work correctly.
> （gh stack sync --help）
> ```

> [!TIP]
>
> `--prune` を付けないと、マージ済みのローカルブランチが溜まっていきます。
> スタック運用では層の入れ替わりが速いので、`sync --prune` を習慣にしてください。

---

## Step 4: 一括マージ — 上位 PR をマージして下層もまとめて着地させる

残り 4 層のうち、`feat/task-store` までの承認が揃った、という設定にします。

`feat/task-store` の PR をマージします。

```bash
gh stack checkout feat/task-store
gh stack merge --squash     # ウィザードで「feat/task-store まで」を選ぶ
```

**下の未マージ層（`feat/task-model` と `feat/task-errors`）も一緒に着地します。**

```bash
gh pr list --state merged
gh pr list --state open
```

`feat/task-api` だけが open で残り、base が `main` に再ターゲットされているはずです。

```bash
gh pr list --json number,title,baseRefName,headRefName --jq '.[] | "\(.number)\t\(.headRefName)\t→ \(.baseRefName)"'
```

ローカルを追随させます。

```bash
gh stack sync --prune
gh stack view
```

---

## Step 5: 最後の層をマージしてスタックを閉じる

```bash
gh stack top
gh stack merge --squash -y  # 残りは最上層までなので、スタック全体をまとめてマージしてよい
gh stack sync --prune
gh stack view
```

全 PR がマージされたので、**スタックは閉じます**。

> [!IMPORTANT]
> 閉じたスタックに後から層を足すことはできません。
> 関連する作業が続く場合は、全部マージしきる前に層を積むか、新しいスタックを作ります。

`main` の内容を確認します。

```bash
# スタックは閉じているので `gh stack trunk` は使えない
# （"You must be on a branch that is part of a stack." で失敗する）
git switch main && git pull
ls src/
git log --oneline | head -10
```

`src/` に model / errors / store / api / index が揃っているはずです。

---

## Step 6: マージ方式の選び方

| 方式             | スタックでの挙動                    | 向くケース                                          |
| ---------------- | ----------------------------------- | --------------------------------------------------- |
| **squash**       | 各層が `main` 上で 1 コミットになる | 層 = 論理単位が明確なとき。**スタックと相性が良い** |
| **merge commit** | 層内のコミット履歴が保たれる        | 層内の途中経過も履歴に残したいとき                  |
| **rebase**       | 層内のコミットが `main` 上に並ぶ    | 線形履歴を保ちたいとき                              |

> [!TIP]
>
> **スタックでは squash が扱いやすい**です。
> 「1 層 = `main` 上の 1 コミット」となり、層の粒度がそのまま履歴の粒度になります。
> revert も層単位でできます（ただし**依存する上層がマージ済みなら、下層だけを戻すと `main` が壊れます**。
> 巻き戻しは上の層から逆順に行います。[10. ロールアウト設計](../docs/10-rollout.md) 参照）。
>
> ただしリポジトリのマージ方式はリポジトリ設定に従います。
> squash が無効化されているリポジトリでは選べません。

### merge queue について

**スタックは merge queue に完全対応しています**（公式ドキュメント: "Stacks fully support merge queues"）。
base ブランチが merge queue を使っている場合、`gh stack merge` は直接マージせず**キューへ投入**します。

| 挙動             | 内容                                                                        |
| ---------------- | --------------------------------------------------------------------------- |
| 順序             | スタック内の全 PR が**正しい順序で**キューに入る                            |
| グループサイズ   | スタックを分割しないよう、設定された最大サイズを**最大 50% まで超過**できる |
| 分割             | それでも収まらない場合、**連続する複数のマージグループへ自動で分割**される  |
| キューからの排除 | ある PR がキューから外れると、**その上の層もすべて外れる**                  |

> [!NOTE]
>
> キューに入った場合、マージはキューの処理を待ちます。
> **キューはマージ方式を自前の設定で決めるため、`--squash` などの指定が反映されない場合があります。**
> また分割されたときは、全層が同時に着地するとは限りません。

---

## Step 7: 後片付け

演習用リポジトリの状態を確認します。

```bash
gh stack view          # スタックがない状態（exit 2）
git branch             # main だけが残っている
gh pr list --state all
```

もし追跡情報が残っている場合:

```bash
gh stack unstack --local     # ローカルの追跡だけ削除
```

---

## 確認ポイント

- [ ] 部分マージ後、上層の base が自動で再ターゲットされることを確認した
- [ ] 一括マージで下層もまとめて着地することを確認した
- [ ] `gh stack sync --prune` でローカルブランチが片付くことを確認した
- [ ] 全層マージ後にスタックが閉じることを確認した
- [ ] squash / merge / rebase の使い分けを説明できる

---

## つまずきポイント

| 症状                                   | 原因と対処                                                                                                  |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| 上層を先にマージしようとして失敗する   | スタックは下から上へしかマージできない。下層を先に処理する                                                  |
| マージがブロックされる                 | その層または**下の層**が必須レビュー / 必須チェックを満たしていない。`gh stack view` で止まっている層を特定 |
| マージ後もローカルに古いブランチが残る | `gh stack sync --prune` を実行する                                                                          |
| exit 4（GitHub API failure）           | 一時的な API エラーか権限不足。`gh auth status` を確認して再実行                                            |
| 閉じたスタックに層を足せない           | 仕様。新しいスタックを作る                                                                                  |

---

## 振り返り課題

1. 5 層のスタックで、第 3 層までレビューが終わった。何をすべきか。
2. 部分マージのあと、なぜ `gh stack sync` が必要か。
3. スタックで squash マージが推奨される理由を、revert の観点から説明せよ。
4. マージが「ブロックされています」と表示された。原因の候補を 2 つ挙げよ。

<details>
<summary>解答</summary>

1. 第 3 層の PR をマージする。第 1・第 2 層も一緒に着地し、第 4・第 5 層は
   base が `main` に自動再ターゲットされて open のまま残る。その後 `gh stack sync --prune`。
2. マージによって `main` が進み、リモートの状態とローカルの追跡情報がずれるため。
   `sync` で fetch → リベース → push → PR 状態同期を行い、ズレを解消する。
3. 1 層 = `main` 上の 1 コミットになるため、`git revert <sha>` で層単位の巻き戻しができる。
   rebase だと層のコミットが `main` 上に複数並ぶため、revert の単位が層と一致しない。
   なお merge commit は `git revert -m 1 <merge-sha>`（GitHub の Revert ボタンも同じ）で
   1 単位として戻せるので、**この点では squash と同等**。差が出るのは履歴の見え方で、
   squash のほうが「1 層 = 1 コミット」と粒度が揃う。
4. (a) その層自身が必須レビュー / 必須チェックを満たしていない。
   (b) **その下の層**が要件を満たしていない（下層が通らないと上層はマージできない）。
   他に: merge queue 待ち、コンフリクト、ブランチ保護のその他ルール。

</details>

---

次は [Lab 08: 既存 PR をスタック化する](lab08-adopt-existing.md) へ。
