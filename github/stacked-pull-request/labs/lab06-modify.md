# Lab 06: スタックの構造を組み替える

所要 30 分 | 使うコマンド: `modify` / `modify --continue` / `modify --abort`

---

## ゴール

積んだあとで「順序が違った」「途中に層を挟みたい」となったときに、
スタックを作り直さず組み替えられるようになる。

> [!IMPORTANT]
>
> **`gh stack modify` は CLI にしかありません。** Web UI に相当機能はないため、
> 並べ替えが必要になる可能性があるチームは、全員が `gh-stack` 拡張を入れておく必要があります。
> （組織展開の論点として [10. ロールアウト設計](../docs/10-rollout.md) でも扱います）

## 開始状態

[Lab 05](lab05-conflict.md) 完了。3 層のスタックがコンフリクト解決済みで最新化されている。

```bash
cd "${PLAYGROUND_DIR:-$HOME/stacked-pr-playground}" && gh stack sync && gh stack view
```

---

## Step 1: 組み替えが必要になる状況を作る

レビューで次の指摘が入った、という設定です。

> 「`README.md` にセットアップ手順を足す変更が入っているが、
> これは他の層と依存関係がない。**最初にマージできるように最下層へ動かしてほしい**」

まず、その状況を作ります。最上層にドキュメント変更を積みます。

> [!IMPORTANT]
>
> **`--auto` だけで submit すると、新しく作られる PR は draft になります**（既存 PR の更新には影響しません）。
> 実機 `gh stack submit --help` に「With `--auto`, new PRs are created as drafts unless you pass `--open`」とあります。
> draft のままだと [Lab 07](lab07-merge.md) でマージできません
> （`gh stack merge` は open かつ draft でないことを要求し、**1 つでも条件を満たさないと全体が失敗します**）。
> 下の手順で `--open` を付けているのはこのためです。

```bash
gh stack top
gh stack add docs/setup-guide

cat >> README.md <<'EOF'

## Setup

1. Install dependencies: npm install
2. Run tests: node --test
EOF

git add README.md
git commit -m "docs: add setup instructions"
gh stack submit --auto --open
gh stack view
```

現在のスタック:

```
docs/setup-guide      ← 最上層。マージは最後になる
feat/task-api
feat/task-store
feat/task-model
main
```

`docs/setup-guide` は他の層に依存していないのに、
このままでは 3 層すべてがマージされるまで着地できません。

---

## Step 2: `gh stack modify` で並べ替える

```bash
gh stack modify
```

対話的なエディタが開き、スタック内の層が並びます。
**`git rebase -i` と同じ要領**で、行を並べ替えたり削除したりできます。

`docs/setup-guide` の行を一番下（trunk のすぐ上）に移動して保存・終了します。

目標の構造:

```
feat/task-api
feat/task-store
feat/task-model
docs/setup-guide      ← 最下層に移動
main
```

保存すると、必要な再リベースが自動で走ります。

---

## Step 3: 結果を確認する

```bash
gh stack view
```

`docs/setup-guide` が最下層になり、`feat/task-model` の base が
`main` から `docs/setup-guide` に変わっているはずです。

GitHub 側にも反映します。

```bash
gh stack submit
```

PR ページで base の付け替えを確認します。

```bash
gh stack bottom
gh pr view --web        # base が main になっている（docs/setup-guide の PR）

gh stack up
gh pr view --web        # base が docs/setup-guide になっている
```

---

## Step 4: コンフリクトが起きた場合

組み替えでは高い確率でコンフリクトが起きます。
[Lab 05](lab05-conflict.md) と同じ流れで解決します。

```bash
# コンフリクトしたら
git status
# ファイルを編集して解決
git add <解決したファイル>
gh stack modify --continue
```

引き返したいとき:

```bash
gh stack modify --abort
```

組み替え前のスタック構造に復元されます。

> [!WARNING]
>
> `modify` の途中でターミナルを閉じたりすると、**exit 10（Modify session interrupted）** の状態になります。
> その場合は `gh stack modify --continue` か `--abort` で決着をつけてから他の操作をしてください。

---

## Step 5: 層を挿入する

「`feat/task-store` の前に、共通のエラー型を定義する層が要る」となった場合。

> [!IMPORTANT]
>
> **`gh stack add` は途中に挿入できません。**
> 公式リファレンスの記述は
> 「現在の HEAD に新しいブランチを作り、**スタックの最上部に追加**してチェックアウトする。
> このコマンドは**スタックの最上層のブランチにいるときに実行する必要がある**」です。
>
> 途中への挿入は **`gh stack modify` の "Insert below" / "Insert above"** を使います。

```bash
gh stack checkout feat/task-model      # 挿入位置の目安となる層へ
gh stack modify
# → 対話画面で feat/task-model を選び、"Insert above" を実行
# → 新しいブランチ名として feat/task-errors を入力
```

挿入後、その層に移動して実装します。

```bash
gh stack checkout feat/task-errors

cat > src/errors.js <<'EOF'
export class TaskValidationError extends Error {
  constructor(errors) {
    super(`invalid task: ${errors.join(', ')}`);
    this.name = 'TaskValidationError';
    this.errors = errors;
  }
}

export class DuplicateTaskError extends Error {
  constructor(id) {
    super(`duplicate task id: ${id}`);
    this.name = 'DuplicateTaskError';
    this.id = id;
  }
}
EOF

git add src/errors.js
git commit -m "feat(errors): add typed task errors"

gh stack rebase --upstack      # 上の層に伝播
gh stack submit
gh stack view
```

現在のスタック:

```
feat/task-api
feat/task-store
feat/task-errors      ← 挿入された
feat/task-model
docs/setup-guide
main
```

---

## Step 6: 層を削除する

「`feat/task-errors` はやっぱり要らない」となった場合。

`gh stack modify` の対話画面で該当行を削除して保存すると、その層がスタックから外れます。

```bash
gh stack modify
# → feat/task-errors の行を削除して保存
```

> [!CAUTION]
>
> `modify` で層を削除すると、**その層のコミットがスタックから外れます**。
> 削除前に `git log --oneline feat/task-errors` でコミット SHA を控えておくと、
> 万一戻したくなったときに `git cherry-pick` で拾えます。

本 Lab では次の Lab で使うので、削除は**実行せず**、手順の確認だけにとどめてください。

> [!CAUTION]
>
> **`--abort` で戻せるのは、エディタで保存する前（`modify` セッションが進行中）のときだけです。**
> 保存して構造変更が確定したあとは `--abort` では戻せません。
> 誤って層を消してしまった場合は、上の CAUTION で控えた SHA から `git cherry-pick` で拾い直すか、
> `gh stack unstack` してから `gh stack init` で組み直します。

```bash
gh stack modify --abort        # 保存前（セッション進行中）なら中断できる
```

---

## Step 7: スタックの解体 — `unstack`

「そもそもスタックにする必要がなかった」場合、スタックを解体できます。

```bash
gh stack unstack               # 現在のスタックを解体（GitHub 上のリンクも解除）
gh stack unstack 1             # stack number 指定
gh stack unstack --local       # ローカル追跡だけ外し、GitHub 上のスタックは残す
```

**解体しても PR とブランチは残ります。** スタックとしてのリンクが外れるだけです。

> [!NOTE]
> 本 Lab では実行しないでください。[Lab 07](lab07-merge.md) でこのスタックを使います。
> 試したい場合は Lab 07 完了後に。

---

## 確認ポイント

- [ ] `gh stack modify` で層を並べ替えられた
- [ ] 並べ替え後に base が正しく付け替わったことを PR ページで確認した
- [ ] 途中の位置に `gh stack modify` の "Insert above" / "Insert below" で層を挿入できた
- [ ] `modify --continue` / `--abort` の役割が分かる
- [ ] `unstack` と PR 削除の違いが分かる

---

## つまずきポイント

| 症状                                      | 原因と対処                                                    |
| ----------------------------------------- | ------------------------------------------------------------- |
| exit 10（Modify session interrupted）     | `modify` が中断された。`--continue` か `--abort` で決着させる |
| 並べ替え後にビルドが壊れる                | 依存の順序を無視して並べた。依存される側が下に来る必要がある  |
| `modify` 後に PR の base が古いまま       | `gh stack submit` を実行していない                            |
| exit 8（Stack locked by another process） | 別プロセスが同じスタックを操作中。終了を待つ                  |
| 対話エディタが意図しないもので開く        | `GIT_EDITOR` / `EDITOR` を設定する（例: `export EDITOR=vim`） |

---

## 振り返り課題

1. Web UI だけで運用しているメンバーが、スタックの並べ替えを頼まれた。何ができるか。
2. 「依存のない独立した変更」をスタックに含めるとき、どの位置に置くのが有利か。理由も。
3. `gh stack unstack` と PR を close することの違いは。
4. `modify` で層を削除すると、その層のコミットはどうなるか。

<details>
<summary>解答</summary>

1. できない。並べ替えは `gh stack` 拡張が必須で Web UI に相当機能がない。
   拡張をインストールするか、CLI を使えるメンバーに依頼する。
   （だからこそ、CLI を使わないチームは**スタックの順序を最初に慎重に決める**必要がある）
2. **最下層**。独立していれば先にマージでき、上層のレビューを待たずに着地する。
   逆に最上層に置くと、依存もないのに全層のマージを待つことになる。
3. `unstack` はスタックのリンクを解除するだけで、PR もブランチも open のまま残る。
   close は PR そのものを閉じる。両者は別の操作。
4. スタックから外れる。ブランチとコミット自体は残るが、スタックの連なりからは切り離される。
   完全に消したいなら別途ブランチを削除する。

</details>

---

次は [Lab 07: マージ戦略を選ぶ](lab07-merge.md) へ。
