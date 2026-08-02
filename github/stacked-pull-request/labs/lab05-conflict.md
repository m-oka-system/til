# Lab 05: コンフリクトを解決する

所要 40 分 | 使うコマンド: `rebase --continue` / `rebase --abort`

---

## ゴール

スタック運用で一番怖い「多段コンフリクト」を、意図的に起こして解決しきる。
`--abort` で安全に引き返す方法も身につける。

## 開始状態

[Lab 04](lab04-propagate.md) 完了。3 層が最新化されている。

```bash
cd "${PLAYGROUND_DIR:-$HOME/stacked-pr-playground}" && gh stack sync && gh stack view
```

---

## Step 1: コンフリクトが起きる構造を作る

3 つの層が**同じファイルの近い行**を触る状況を作ります。
`src/index.js` を公開 API のバレルファイルにします。

### 第 1 層

```bash
gh stack bottom
cat > src/index.js <<'EOF'
export { createTask, validateTask, VALID_STATUSES, MAX_TITLE_LENGTH } from './model.js';
EOF
git add src/index.js
git commit -m "feat(model): export model API from index"
```

### 第 2 層

```bash
gh stack up
gh stack rebase --upstack    # 第 1 層の変更を取り込む
cat > src/index.js <<'EOF'
export { createTask, validateTask, VALID_STATUSES, MAX_TITLE_LENGTH } from './model.js';
export { TaskStore } from './store.js';
EOF
git add src/index.js
git commit -m "feat(store): export TaskStore from index"
```

### 第 3 層

```bash
gh stack up
gh stack rebase --upstack
cat > src/index.js <<'EOF'
export { createTask, validateTask, VALID_STATUSES, MAX_TITLE_LENGTH } from './model.js';
export { TaskStore } from './store.js';
export { createApi } from './api.js';
EOF
git add src/index.js
git commit -m "feat(api): export createApi from index"
```

状態を確認して push します。

```bash
gh stack view
gh stack submit --auto --open   # 新規 PR が draft にならないよう --open を付ける
```

これで「各層が `src/index.js` に 1 行ずつ足す」構造ができました。

---

## Step 2: 意図的にコンフリクトを起こす

レビューで「バレルファイルは名前空間ごとにまとめたい」という指摘が入った、という設定です。
**第 1 層**の書き方を変えます。

```bash
gh stack bottom
cat > src/index.js <<'EOF'
import * as model from './model.js';

export { model };
EOF
git add src/index.js
git commit -m "refactor(model): export model as a namespace"
```

上層に伝播させます。

```bash
gh stack rebase
```

**コンフリクトで停止します。** 終了コードを確認してください。

```bash
echo "exit=$?"
# → exit=3  (Rebase conflict)
```

---

## Step 3: 第 1 段のコンフリクトを解決する

いまどこで止まっているかを確認します。

```bash
git status
git branch --show-current     # → feat/task-store
```

`src/index.js` にコンフリクトマーカーが入っています。

```bash
cat src/index.js
```

```
<<<<<<< HEAD
import * as model from './model.js';

export { model };
=======
export { createTask, validateTask, VALID_STATUSES, MAX_TITLE_LENGTH } from './model.js';
export { TaskStore } from './store.js';
>>>>>>> feat(store): export TaskStore from index
```

**解決の指針**: 第 1 層の新しい方針（名前空間 export）を採用しつつ、
第 2 層が足そうとしていた `TaskStore` も残します。

```bash
cat > src/index.js <<'EOF'
import * as model from './model.js';
import * as store from './store.js';

export { model, store };
EOF

git add src/index.js
gh stack rebase --continue
```

> [!IMPORTANT]
>
> `git rebase --continue` **ではなく** `gh stack rebase --continue` を使います。
> 生の git で続けると、残りの層へのカスケードが実行されず、スタックが中途半端な状態になります。

---

## Step 4: 第 2 段のコンフリクトを解決する

`feat/task-api` でも同じ理由で止まります。

```bash
git status
git branch --show-current     # → feat/task-api
cat src/index.js
```

同じ方針で解決します。

```bash
cat > src/index.js <<'EOF'
import * as model from './model.js';
import * as store from './store.js';
import * as api from './api.js';

export { model, store, api };
EOF

git add src/index.js
gh stack rebase --continue
```

これでリベースが完走します。

```bash
gh stack view
git log --oneline feat/task-api | head -6
```

---

## Step 5: 反映と確認

```bash
gh stack submit
```

各層の PR を見て、コンフリクト解決の結果が意図通りか確認します。

```bash
gh stack bottom && gh pr view --web    # index.js が namespace 形式
gh stack up     && gh pr view --web    # store が 1 行追加されただけの差分
gh stack up     && gh pr view --web    # api が 1 行追加されただけの差分
```

> [!TIP]
> 解決が正しければ、**各層の差分は「その層の 1 行追加」だけ**になります。
> もし上層の差分に model の変更が混ざっていたら、解決を間違えています
> （下層の変更を上層で「再適用」してしまっている）。これはスタック運用でよくある事故です。

---

## Step 6: `--abort` で引き返す

コンフリクトが複雑すぎて「一旦やめたい」ときの手順です。

もう一度コンフリクトを起こします。

```bash
gh stack bottom
cat > src/index.js <<'EOF'
export * as model from './model.js';
EOF
git add src/index.js
git commit -m "refactor(model): use export-star namespace syntax"

gh stack rebase
# → exit 3 でコンフリクト
```

ここで中断します。

```bash
gh stack rebase --abort
```

ブランチがリベース開始前の状態に戻ります。

```bash
git status                    # rebase in progress ではない
gh stack view
```

> [!NOTE]
>
> `--abort` が戻すのは**リベースの途中経過**です。
> Step 6 で第 1 層に作ったコミット自体は残っています。
> それも取り消したい場合は `git reset --hard HEAD~1` を第 1 層で実行してください。

演習を続けるため、Step 6 のコミットを取り消して元に戻します。

```bash
gh stack bottom && git log --oneline -1     # 最下層へ移動し、消す対象を確認する
```

> [!CAUTION]
>
> `git reset --hard` は**確認なしにコミットを捨てます**。上の出力が Step 6 で作ったコミット
> （`refactor(model): use export-star namespace syntax`）であることを必ず確かめてから、次を実行してください。
> SHA を控えておけば、間違えても `git cherry-pick <SHA>` で拾い直せます。
>
> **次のブロックは確認できてから実行します。** 上のブロックと分けてあるのは、
> コピーボタンでまとめて実行されると `gh stack bottom` の成否に関わらず破棄が走るためです。

確認できたら、コミットを取り消してスタックを元に戻します。

```bash
git reset --hard HEAD~1
gh stack rebase
gh stack submit
```

---

## コンフリクト解決の原則

| 原則                                                 | 理由                                                                   |
| ---------------------------------------------------- | ---------------------------------------------------------------------- |
| **下層の意図を優先する**                             | 下層が先にマージされる。上層は下層に合わせるのが自然                   |
| **上層の差分は「その層の追加分」だけに保つ**         | 下層の変更を再適用すると、マージ時に二重適用や差分崩れが起きる         |
| **`gh stack rebase --continue` を使う**              | 生の `git rebase --continue` はカスケードを止めてしまう                |
| **迷ったら `--abort`**                               | 途中で判断がつかないまま進めるより、下層の設計を先に確定させた方が速い |
| **層をまたぐ大きな設計変更は、リベース前に相談する** | 下層の方針転換は上層全部にコンフリクトを撒く                           |

### コンフリクトを減らす設計

- **同じファイルを複数層で触らない**ように層を切る（一番効く）
- バレルファイル・設定ファイル・ロックファイルのような「全員が触る 1 ファイル」は、
  可能なら最上層にまとめる
- 下層の設計は、上層を積む前にレビューを 1 周させる

---

## 確認ポイント

- [ ] `gh stack rebase` がコンフリクトで exit 3 で止まることを確認した
- [ ] `gh stack rebase --continue` で次の層へカスケードが進んだ
- [ ] 2 段以上のコンフリクトを解決しきった
- [ ] 解決後、各層の差分がその層の追加分だけになっていることを確認した
- [ ] **各層で `node --test` が通ることを確認した**（Lab 09 の CI 実習の前提）
- [ ] `gh stack rebase --abort` で安全に引き返せた

---

## つまずきポイント

| 症状                                           | 原因と対処                                                                                                                                                                        |
| ---------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--continue` が「解決されていない」と言う      | `git add` していないファイルがある。`git status` で確認                                                                                                                           |
| exit 7（Rebase already in progress）           | 前回のリベースが未完了。`--continue` か `--abort` で決着をつける                                                                                                                  |
| 上層の差分に下層の変更が混ざる                 | コンフリクト解決で下層の変更を再適用した。**リベース進行中なら** `gh stack rebase --abort`。完走後は `--abort` が使えないので、該当層で修正コミットを積むか `git reflog` から戻す |
| `git rebase --continue` を打ってしまった       | カスケードが止まっている。`gh stack rebase` を再実行して残りの層を処理する                                                                                                        |
| コンフリクトマーカーが残ったままコミットされた | `git grep '<<<<<<<'` で検出。該当層で修正コミットを積む                                                                                                                           |

---

## 振り返り課題

1. `git rebase --continue` ではなく `gh stack rebase --continue` を使う理由は。
2. 5 層のスタックで第 1 層に大きな設計変更を入れると、最悪何回コンフリクト解決が必要か。
3. コンフリクト解決後、PR #3 の "Files changed" に `model.js` の変更が出ていた。何が起きたか。
4. 「全層が触る 1 ファイル」を層のどこに置くべきか。理由も。

<details>
<summary>解答</summary>

1. `gh stack rebase --continue` は、その層のリベース完了後に**上の層へカスケードを続行**する。
   生の git だとその層で止まり、上層が古いまま残る。
2. 4 回（第 2 層〜第 5 層のそれぞれで発生しうる）。
   これが「下層の設計は先に固める」べき理由。
3. コンフリクト解決の際に、下層の変更を上層で再適用してしまった。
   上層のコミットは「その層の差分」だけを持つべき。該当層をやり直す。
4. **最上層**に置く。下層に置くと、上層すべてが必ずそのファイルでコンフリクトしうる。
   最上層なら、下から伝播してくるコンフリクトの回数が最小になる。

</details>

---

次は [Lab 06: スタックの構造を組み替える](lab06-modify.md) へ。
