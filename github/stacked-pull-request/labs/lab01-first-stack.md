# Lab 01: 最初のスタックを作る

所要 40 分 | 使うコマンド: `init` / `add` / `push` / `submit` / `view`

---

## ゴール

タスク管理 API を **3 層のスタック**に分解して起票する。

| 層  | ブランチ          | 内容                       | 依存  |
| --- | ----------------- | -------------------------- | ----- |
| 3   | `feat/task-api`   | HTTP ハンドラ              | store |
| 2   | `feat/task-store` | インメモリ永続化           | model |
| 1   | `feat/task-model` | データ構造とバリデーション | —     |

## 開始状態

- [環境準備](../docs/01-setup.md) が完了している
- 練習用リポジトリ（既定は `~/stacked-pr-playground`。`PLAYGROUND_DIR` で変えた場合はそのパス）にいて `git status` がクリーン
- `main` ブランチにいる

```bash
cd "${PLAYGROUND_DIR:-$HOME/stacked-pr-playground}" && git switch main && git pull
```

---

## Step 1: スタックを初期化する

`gh stack init` は、trunk の上に最初のブランチを作り、スタックの追跡を開始します。

```bash
gh stack init feat/task-model
```

引数なしで実行すると対話モードになり、ブランチ名を尋ねられます。
また「現在のブランチを最初の層として使うか」も選べます。

```bash
gh stack init          # 対話モード
```

trunk が `main` 以外（リリースブランチなど）の場合は明示します。

```bash
gh stack init -b release/2026-08 feat/task-model
```

実行後の状態を確認します。

```bash
git branch --show-current    # → feat/task-model
gh stack view
```

> [!NOTE]
>
> `gh stack init` に既存のブランチ名を渡すと、そのブランチは**そのままスタックに取り込まれます**（adopt）。
> 存在しないブランチ名を渡した場合は新規作成されます。
> 複数のブランチ名をまとめて渡すこともできます: `gh stack init b1 b2 b3`

---

## Step 2: 第 1 層を実装する

`src/model.js` を作ります。

```bash
cat > src/model.js <<'EOF'
const VALID_STATUSES = ['todo', 'doing', 'done'];

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
  if (!VALID_STATUSES.includes(task.status)) errors.push(`status must be one of ${VALID_STATUSES.join('|')}`);
  return errors;
}

export { VALID_STATUSES };
EOF
```

コミットします。

```bash
git add src/model.js
git commit -m "feat(model): add Task data structure and validation"
```

---

## Step 3: 第 2 層を積む

`gh stack add` は、現在の HEAD に新しいブランチを作り、**スタックの最上部に追加**してチェックアウトします。

```bash
gh stack add feat/task-store
```

> [!IMPORTANT]
>
> `gh stack add` は**スタックの最上層のブランチにいるときに実行する必要があります**。
> いま `feat/task-model` は最上層なので問題ありませんが、途中の層にいるときは
> 先に `gh stack top` で移動してください。
> **スタックの途中に層を挿入したい場合は `add` ではなく `gh stack modify` を使います**
> （[Lab 06](lab06-modify.md) で扱います）。

`src/store.js` を作ります。**第 1 層の `model.js` に依存している**点に注目してください。

```bash
cat > src/store.js <<'EOF'
import { createTask } from './model.js';

export class TaskStore {
  #tasks = new Map();

  add(input) {
    const task = createTask(input);
    if (this.#tasks.has(task.id)) {
      throw new Error(`duplicate task id: ${task.id}`);
    }
    this.#tasks.set(task.id, task);
    return task;
  }

  get(id) {
    return this.#tasks.get(id) ?? null;
  }

  list() {
    return [...this.#tasks.values()];
  }

  remove(id) {
    return this.#tasks.delete(id);
  }
}
EOF

git add src/store.js
git commit -m "feat(store): add in-memory TaskStore"
```

---

## Step 4: 第 3 層を積む（ステージ + コミット + ブランチ作成を一発で）

`gh stack add` には、変更のステージングとコミットを同時に行うフラグがあります。

| フラグ          | 意味                                       |
| --------------- | ------------------------------------------ |
| `-A, --all`     | 未追跡ファイルを含むすべての変更をステージ |
| `-u, --update`  | 追跡済みファイルのみステージ               |
| `-m, --message` | 新しい層を作り、**その層に**コミットを作る |

`-A` と `-u` は同時には使えません。
`-m` は必須ではなく、省略して `-A` / `-u` だけを渡すとコミットメッセージ用のエディタが開きます。

まずブランチだけ追加します。

```bash
gh stack add feat/task-api
```

`src/api.js` を作ります。

```bash
cat > src/api.js <<'EOF'
import { TaskStore } from './store.js';

export function createApi(store = new TaskStore()) {
  return {
    'POST /tasks': (body) => ({ status: 201, body: store.add(body) }),
    'GET /tasks': () => ({ status: 200, body: store.list() }),
    'GET /tasks/:id': ({ id }) => {
      const task = store.get(id);
      return task ? { status: 200, body: task } : { status: 404, body: { error: 'not found' } };
    },
    'DELETE /tasks/:id': ({ id }) =>
      store.remove(id) ? { status: 204 } : { status: 404, body: { error: 'not found' } },
  };
}
EOF

git add src/api.js
git commit -m "feat(api): add HTTP handlers for tasks"
```

> [!TIP]
> 慣れてきたら、次のように 1 コマンドで「次の層を作成 → ステージ → コミット」ができます。
> **コミットは新しく作られた層に入ります。**
>
> ```bash
> gh stack add -Am "feat(api): add HTTP handlers for tasks" feat/task-api
> ```

---

## Step 5: ローカルのスタックを確認する

```bash
gh stack view
```

3 つの層が trunk (`main`) の上に積まれた図が表示されます。
現在のブランチにマーカーが付いているはずです。

コンパクトに見たいとき、スクリプトから使いたいとき:

```bash
gh stack view --short
gh stack view --json
```

> [!NOTE]
>
> `--json` の出力構造は preview 中に変わる可能性があります。
> スクリプトに組み込む前に、自分の環境で `gh stack view --json | jq .` を実行して
> 実際のキー名を確認してください。

---

## Step 6: リモートに push する

```bash
gh stack push
```

スタック内のアクティブなブランチをすべてリモートに push します。
push 先のリモートを変えたい場合は `--remote upstream` のように指定します。

この時点ではまだ **PR は作られていません**。ブランチが上がっただけです。

```bash
git branch -r | grep feat/task
```

---

## Step 7: PR を作ってスタックとして登録する

```bash
gh stack submit
```

`submit` は次を一度に行います。

1. 全ブランチを push（`push` 相当）
2. 各層の PR を作成 or 更新
3. GitHub 上でそれらを**スタックとしてリンク**

各 PR のタイトル・本文を編集するためエディタが開きます。
**PR ごとに 3 回開くのではなく、全 PR が 1 画面にまとまって開きます。** まとめて書いて `Ctrl+S` で確定します。

| フラグ            | 意味                                       | 使いどころ                    |
| ----------------- | ------------------------------------------ | ----------------------------- |
| `--auto`          | エディタを開かず、タイトルを自動生成       | 素早く起票したいとき          |
| `--open`          | draft ではなく **ready for review** で作成 | すぐレビューに出すとき        |
| `--remote <name>` | push 先リモートを指定                      | fork ではない別リモート運用時 |

エディタが煩わしければ:

```bash
gh stack submit --auto --open
```

---

## Step 8: GitHub 上で確認する

```bash
gh stack view          # PR 番号が表示される
gh pr list             # 3 本の PR が並ぶ
```

ブラウザで最下層の PR を開きます。

```bash
gh stack bottom        # 最下層に移動
gh pr view --web
```

**確認すること:**

- PR #1 の base が `main` になっている
- PR #2 の base が `feat/task-model`、PR #3 の base が `feat/task-store` になっている
- ヘッダーの `Open` バッジの隣に **stack icon**（`1/3` のような層番号）が出ている
- merge box の中に **stack map**（スタック全体の俯瞰）が表示されている（この 2 つの違いは Lab 03 で扱います）
- PR #2 の "Files changed" に `src/model.js` が**含まれていない**（その層の差分だけが見える）

> [!NOTE]
>
> **この差分表示自体は、スタック PR で初めて可能になったものではありません。**
> GitHub の PR は昔から「base と head の差分」を表示します。従来のブランチ運用でも
> PR #2 の base を手で `feat/task-model` に設定すれば、同じく `src/model.js` は出ませんでした。
> 下層の変更が混ざるのは、base を `main` のままにした場合です。
>
> スタック PR の価値は差分表示そのものではなく、**base の設定と維持を GitHub 側が引き受ける**点にあります。
>
> - 層を積むたびに base を手で指定しなくてよい（`gh stack add` が自動で設定する）
> - 下層を直したときの上層への rebase が 1 コマンド（Lab 04）
> - 下層のマージ後に上層を整合させる（Lab 07）
> - stack map で全体像とレビュー状況が見える

---

## 確認ポイント

- [ ] `gh stack view` に 3 層 + trunk が表示される
- [ ] GitHub 上に 3 本の PR があり、base が数珠つなぎになっている
- [ ] 各 PR の "Files changed" にその層のファイルだけが出る
- [ ] 各 PR の merge box に stack map が表示される

---

## つまずきポイント

| 症状                                                | 原因と対処                                                                                                       |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `gh stack add` が「スタックがない」で失敗（exit 2） | `gh stack init` を先に実行する。あるいは trunk にいるだけで層にいない                                            |
| `gh stack add` が「最上層で実行せよ」と言う         | 途中の層にいる。`gh stack top` してから実行する                                                                  |
| `submit` で PR が作られない                         | ブランチにコミットが 1 つもない。空の層は PR にできない                                                          |
| PR の base が `main` に揃ってしまう                 | `gh stack` を使わず手動で `git push` + `gh pr create` した可能性。`gh stack submit` で作り直す                   |
| exit 9 が返る                                       | そのリポジトリでスタック機能が有効になっていない。[トラブルシューティング](../reference/troubleshooting.md) 参照 |

---

## 振り返り課題

1. `gh stack push` と `gh stack submit` の違いを 1 文で説明せよ。
2. `gh stack add -Am "msg" branch-name` を分解すると、どの git コマンド相当の処理が走っているか。
3. Step 4 で `src/api.js` が `src/store.js` を import している。もし層の順序を逆にして
   `feat/task-api` を第 1 層にしていたら、CI はどうなるか。

<details>
<summary>解答</summary>

1. `push` はブランチをリモートに上げるだけ。`submit` は push に加えて PR の作成・更新と、GitHub 上でのスタックのリンクまで行う。
2. 新ブランチ作成 + スタックへの追加 + checkout → `git add -A` → `git commit -m "msg"`。
   **コミットは新しく作られた層に入ります**（実行時にいた層ではありません）。
   例外は、いまいる層にまだコミットが 1 つもない場合で、そのときは層を作らずその場でコミットされます。
3. `feat/task-api` 単体では `./store.js` が存在せず、`src/api.js` の import が解決できない。
   実務ではその層の CI が落ちる。**各層が単体で CI を通る**ように依存の下から順に積む、
   というのがスタック設計の原則。
   ただし**本教材の smoke test は `src/index.js` しか読まないため、この時点では
   `node --test` が通ってしまい、実際には観測できません。**
   各層に対応するテストを置いて初めて検出できます（[Lab 09](lab09-ci-protection.md) で扱います）。

</details>

---

次は [Lab 02: スタックを見る・移動する](lab02-navigate.md) へ。
