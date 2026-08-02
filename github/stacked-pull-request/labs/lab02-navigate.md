# Lab 02: スタックを見る・移動する

所要 20 分 | 使うコマンド: `view` / `up` / `down` / `top` / `bottom` / `trunk` / `switch` / `checkout`

---

## ゴール

スタック内を迷わず移動できるようになる。`git switch` を打たずに層を行き来する感覚を身につける。

## 開始状態

[Lab 01](lab01-first-stack.md) 完了。3 層のスタックが GitHub 上にある。

```bash
cd "${PLAYGROUND_DIR:-$HOME/stacked-pr-playground}" && gh stack view
```

---

## Step 1: 3 つの表示モードを使い分ける

```bash
gh stack view              # 通常表示。層・PR 番号・状態
gh stack view --short      # コンパクト表示。ブランチ名だけを素早く確認
gh stack view --json       # 機械可読。スクリプトや jq と組み合わせる
```

`--json` で PR 番号だけ抜き出す例:

```bash
gh stack view --json | jq .
```

> [!NOTE]
> JSON のキー構造は preview 中に変更される可能性があります。
> 自動化に使う前に、必ず自分の環境で出力を確認してください。

---

## Step 2: 相対移動 — `up` / `down`

trunk に近い方が「下」、離れる方が「上」です。

```bash
gh stack bottom            # 最下層 feat/task-model へ
git branch --show-current

gh stack up                # 1 つ上 → feat/task-store
git branch --show-current

gh stack up                # さらに 1 つ上 → feat/task-api
git branch --show-current

gh stack down 2            # 2 つ下 → feat/task-model
git branch --show-current
```

`up` / `down` は数値引数を取ります（省略時は 1）。

---

## Step 3: 絶対移動 — `top` / `bottom` / `trunk`

```bash
gh stack top               # 最上層へ
gh stack bottom            # 最下層へ
gh stack trunk             # trunk（main）へ
```

`gh stack trunk` は「スタックから一旦離れて `main` の状態を見たい」ときに使います。
`git switch main` と違い、スタックの追跡情報を保ったまま戻れます。

```bash
gh stack trunk
gh stack view              # trunk にいてもスタック全体は見える
gh stack bottom            # スタックに復帰
```

---

## Step 4: 対話的に選ぶ — `switch`

層が増えてくると `up` / `down` の回数を数えるのが面倒になります。

```bash
gh stack switch
```

一覧から選択して直接移動できます。5 層以上のスタックではこれが主力になります。

---

## Step 5: 別のスタックや PR から入る — `checkout`

`gh stack checkout` は**スタックの外から**特定の層に入るためのコマンドです。
4 通りの指定ができます。

```bash
gh stack checkout 1                                      # stack number で指定
gh stack checkout 42                                     # PR 番号で指定
gh stack checkout https://github.com/OWNER/REPO/pull/42  # PR の URL で指定
gh stack checkout feat/task-store                        # ブランチ名で指定
```

> [!IMPORTANT]
>
> **数字だけを渡した場合、まず stack number として解決されます。**
> それに一致するスタックが無ければ PR 番号、次にブランチ名の順で試されます
> （`gh stack checkout --help`: "A bare number is resolved as a stack number first"）。
> PR 番号のつもりで打った数字が別のスタックを指すことがあるので、
> 紛らわしいときは URL かブランチ名で指定してください。
> **`gh stack merge` も同じ解決順です**（[Lab 07](lab07-merge.md) で扱います）。

**実務で一番使うのはこれです。** レビュー依頼の Slack に貼られた PR URL を
そのまま渡せば、必要なブランチを fetch してその層に入れます。

試してみます。まず PR 番号を確認:

```bash
gh pr list
```

`main` に戻ってから、PR 番号で 2 層目に飛びます。

```bash
gh stack trunk
gh stack checkout <PR #2 の番号>
git branch --show-current      # → feat/task-store
```

> [!TIP]
> 「同僚のスタックをレビューするためにローカルに落としたい」ときも `gh stack checkout <PR URL>` です。
> 必要なブランチ群が取得され、スタックとして追跡されます。

---

## Step 6: 移動チートを体で覚える

次を順に打ち、毎回 `git branch --show-current` で現在地を確認してください。

```bash
gh stack bottom && git branch --show-current
gh stack up      && git branch --show-current
gh stack top     && git branch --show-current
gh stack down    && git branch --show-current
gh stack trunk   && git branch --show-current
gh stack checkout feat/task-api && git branch --show-current
```

---

## 確認ポイント

- [ ] `up` / `down` / `top` / `bottom` / `trunk` の 5 つを説明なしで使い分けられる
- [ ] `gh stack switch` で任意の層に飛べる
- [ ] PR の URL だけからその層をローカルに checkout できる
- [ ] `gh stack view --short` と `--json` の使い分けが分かる

---

## つまずきポイント

| 症状                                            | 原因と対処                                                                              |
| ----------------------------------------------- | --------------------------------------------------------------------------------------- |
| `up` で「これ以上上がない」                     | すでに最上層。`gh stack view` で現在地を確認                                            |
| `checkout` で exit 6（Disambiguation required） | 指定が曖昧。ブランチ名が複数スタックに存在するなど。PR 番号か stack number で指定し直す |
| `checkout` で exit 2                            | そのスタック / PR が見つからない。番号や URL を確認                                     |
| 移動しようとして「作業ツリーが汚い」と言われる  | 未コミットの変更がある。`git stash` するかコミットしてから移動                          |

---

## 振り返り課題

1. `gh stack trunk` と `git switch main` の違いは何か。
2. 同僚から `https://github.com/acme/app/pull/318` のレビューを頼まれた。
   このスタックの下の層も含めてローカルで動かしたい。最短のコマンドは。
3. 7 層のスタックで、最上層から 4 層目に移動する方法を 3 通り挙げよ。

<details>
<summary>解答</summary>

1. どちらも `main` に移動するが、`gh stack trunk` はスタックの文脈を保ったまま移動する。
   直後に `gh stack up` / `bottom` でスタックに復帰できる。
2. `gh stack checkout https://github.com/acme/app/pull/318`
   （必要なブランチ群が fetch され、スタックとして追跡される）
3. `gh stack down 3` / `gh stack bottom` してから `gh stack up 3` / `gh stack switch` で対話選択。
   （層のブランチ名が分かっていれば `gh stack checkout <branch>` でもよい）

</details>

---

次は [Lab 03: Web UI でレビューする](lab03-review.md) へ。
