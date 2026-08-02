# Lab 09: ブランチ保護と CI

所要 40 分 | 舞台: GitHub Actions・リポジトリ設定

---

## ゴール

「中間層の PR にもブランチ保護と CI が効く」ことを実際に確認し、
スタック導入時の **CI 実行回数の増加**という現実的なコストを把握する。

## 開始状態

[Lab 08](lab08-adopt-existing.md) 完了。`legacy/*` の 3 層スタックが存在する。

```bash
cd "${PLAYGROUND_DIR:-$HOME/stacked-pr-playground}" && gh stack view
```

---

## Step 1: CI ワークフローを追加する

`main` に直接ワークフローを追加します（スタックの外で作業）。

```bash
gh stack trunk && git pull    # スタックを離れて trunk へ
mkdir -p .github/workflows

cat > .github/workflows/ci.yml <<'EOF'
name: CI

on:
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
      - name: Run tests
        run: node --test

      - name: Dump stack metadata
        env:
          STACK_JSON: ${{ toJSON(github.event.pull_request.stack) }}
        run: |
          echo "--- github.event.pull_request.stack ---"
          echo "$STACK_JSON"
EOF

# trunk にいることを確かめてから push する（層にいたまま実行すると誤った PR にコミットが入る）
[ "$(git branch --show-current)" = "main" ] \
  && git add .github/workflows/ci.yml \
  && git commit -m "ci: add pull request workflow" \
  && git push origin main
```

> [!IMPORTANT]
>
> **この演習で走るテストは最小限です。** `bootstrap-playground.sh` が置く `test/smoke.test.js` は
> 「エントリポイントが import できるか」を見るだけで、Lab 08 で作った
> `logger.js` / `metrics.js` / `telemetry.js` の中身までは検証しません。
> ここで確認できるのは「**全層でワークフローが発火すること**」であって、
> 「各層の実装が健全なこと」ではありません。
>
> 実務では **各層に対応するテストを同じ層へ置いてください**
> （[10. ロールアウト設計](../docs/10-rollout.md) の「層の切り方」の規約）。
> これを守らないと、教材が繰り返し述べてきた「各層が単体で CI を通る」という前提が
> 形だけのものになり、**壊れた中間層を部分マージして `main` を壊します。**

> [!IMPORTANT]
>
> `on.pull_request.branches` に **`main` しか書いていない**点に注目してください。
> 中間層の PR は `legacy/logger` などを base にしているので、
> 素朴に考えれば「発火しない」はずです。

---

## Step 2: 全層で CI が走ることを確認する

スタックを最新化して再 submit し、CI をトリガーします。

```bash
gh stack checkout legacy/logger
gh stack sync
```

各層のチェック状態を確認します。

```bash
gh stack bottom && gh pr checks
gh stack up     && gh pr checks
gh stack up     && gh pr checks
```

**3 層すべてで CI が走ります。**

公式ドキュメントの記述:

> A GitHub Actions workflow that triggers on `pull_request` events targeting `main` runs for every pull request in the stack.

つまり、`branches: [main]` フィルタを書いていても、
**スタック内の全 PR で発火します**。GitHub がスタックの最終着地先を見て判定するためです。

### ここが導入時の最大のコスト

| 従来                    | スタック                                         |
| ----------------------- | ------------------------------------------------ |
| PR 1 本 → CI 1 回       | 5 層のスタック → CI **5 回**                     |
| 修正して push → CI 1 回 | 下層を修正して sync → 全層リベース → CI **5 回** |

CI が 10 分かかるリポジトリで 5 層のスタックを回すと、
1 回の修正で 50 分ぶんの CI 時間を消費します。
**これは想像以上に効きます。**

---

## Step 3: スタックメタデータを読む

CI ログの「Dump stack metadata」ステップを確認します。

```bash
gh stack bottom
gh run list --limit 5
gh run view <run-id> --log | grep -A 20 "github.event.pull_request.stack"
```

通常の（スタックでない）PR では、この値は `null` です。
スタック内の PR では、スタックに関するメタデータが入ります。

> [!NOTE]
>
> `stack` オブジェクトの**フィールド構成は preview 中に変わる可能性があります**。
> 本教材ではあえて具体的なフィールド名を書いていません。
> 上のログ出力で実際の構造を確認し、自分の環境の値を基準にワークフローを組んでください。

---

## Step 4: メタデータで CI を最適化する

「重い E2E テストは最上層でだけ走らせる」といった最適化ができます。

Step 3 で確認した実際のフィールド構成に合わせて条件を書きます。以下は骨格の例です。

```yaml
jobs:
  unit:
    # 全層で走らせる（各層が単体で健全であることを保証）
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: node --test

  e2e:
    # 重いジョブはスタックのメタデータで絞る。
    # position == size が「最上層」を表す（通常 PR は stack が null なので常に実行）。
    if: ${{ github.event.pull_request.stack == null || github.event.pull_request.stack.position == github.event.pull_request.stack.size }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "run expensive e2e here"
```

### 最適化の考え方

| ジョブ                                  | スタックでの方針                                         |
| --------------------------------------- | -------------------------------------------------------- |
| Lint / 型チェック / 単体テスト          | **全層で走らせる**。各層が単体で健全である保証が崩れる   |
| 統合テスト                              | 層による。下層が壊れていれば上層も壊れるので、全層が理想 |
| E2E / 性能テスト / セキュリティスキャン | **最上層のみ**でよいことが多い。ここでコストを削る       |
| デプロイプレビュー                      | 最上層のみ。層ごとにプレビュー環境を立てる意味は薄い     |

> [!WARNING]
> 単体テストを「最上層のみ」にすると、
> **中間層が壊れたまま `main` にマージされる**危険があります。
> 部分マージした瞬間に `main` が壊れます。削るのは重いジョブだけにしてください。

---

## Step 5: ブランチ保護が全層に効くことを確認する

`main` に必須レビューを設定します。

> [!WARNING]
>
> **対象リポジトリを必ず明示してください。** `{owner}/{repo}` はカレントディレクトリのリモートから
> 解決されます。別のリポジトリにいるときにこれを実行すると、**`-X PUT` は全置換なので
> そのリポジトリの既存のブランチ保護設定を丸ごと上書きします。**
> 業務リポジトリで実行すると、承認数・管理者バイパス・push 制限が下の JSON の内容に置き換わります。

```bash
# 練習用リポジトリに固定する
TARGET="$(gh api user --jq .login)/${PLAYGROUND_REPO:-stacked-pr-playground}"
echo "$TARGET"    # 対象を目で確認してから次へ進む

gh api -X PUT "repos/$TARGET/branches/main/protection" \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": false,
    "contexts": ["test"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1
  },
  "restrictions": null
}
EOF
```

> [!NOTE]
> private リポジトリでのブランチ保護は、プランによって利用できない場合があります。
> API がエラーを返す場合は、**この Step は読むだけにする**のを第一に検討してください。
>
> どうしても動かして確かめたい場合のみ public にできますが、**確認が済んだら必ず private に戻してください。**
>
> ```bash
> # 対象を必ず明示する。省略するとカレントディレクトリのリモートが対象になる
> TARGET="$(gh api user --jq .login)/${PLAYGROUND_REPO:-stacked-pr-playground}"
>
> gh repo edit "$TARGET" --visibility public --accept-visibility-change-consequences   # 公開する
> gh repo edit "$TARGET" --visibility private --accept-visibility-change-consequences  # 確認後に戻す
> ```
>
> 練習用リポジトリは最終的に `reset-playground.sh` で削除しますが、それまでの間は
> 公開状態が続きます。業務に関わる内容を置いていないか確認してから実行してください。

保護を設定したうえで、**中間層**の PR をマージしようとしてみます。

> [!IMPORTANT]
>
> **先に読んでください。マージは不可逆です。**
>
> **あなたがこのリポジトリの管理者なら、ブロックされずにマージが通ってしまいます。**
> 上の保護設定は `"enforce_admins": false`（管理者にはルールを強制しない）にしてあるためです。
> これは Step 6 で `git push origin main` を通すために必要な設定でもあります。
>
> そのまま実行すると `legacy/metrics` とその下の層が**着地してしまい、以降の Step の前提が壊れます。**
> ブロックを観測したいなら、**マージを試す前に**管理者にも強制する設定へ変えてください。
>
> ```bash
> TARGET="$(gh api user --jq .login)/${PLAYGROUND_REPO:-stacked-pr-playground}"
>
> gh api -X POST "repos/$TARGET/branches/main/protection/enforce_admins"    # 有効化してから下を実行
> ```
>
> 観測できたら、Step 6 へ進む前に戻します。
>
> ```bash
> gh api -X DELETE "repos/$TARGET/branches/main/protection/enforce_admins"  # 無効化
> ```

```bash
gh stack checkout legacy/metrics
gh stack merge --squash     # ウィザードで legacy/metrics までを選ぶ
```

`enforce_admins` を有効にしていれば、承認がないためブロックされます。
無効のまま（既定）なら管理者バイパスで通るので、その場合は上の手順で有効化してから試してください。

### 検証すべき挙動

公式ドキュメントの記述:

- 必須レビューと必須ステータスチェックは、**スタックの base ブランチに対して**全 PR で評価される
- **CODEOWNERS はすべての層に適用される**
- マージは、**対象の PR とその下のすべての依存層**が要件を満たすまでブロックされる

つまり「中間層だから保護が緩い」ということはありません。
`main` を直接ターゲットしていなくても、`main` と同じ基準が適用されます。

---

## Step 6: CODEOWNERS を層単位で使う

スタックの利点のひとつは、**層ごとに適切なレビュアーが自動で割り当たる**ことです。

```bash
gh stack trunk && git pull    # スタックを離れて trunk へ
mkdir -p .github

cat > .github/CODEOWNERS <<'EOF'
# 層ごとにオーナーが変わる構成の例
src/model.js     @data-team
src/store.js     @data-team
src/api.js       @api-team
src/logger.js    @platform-team
src/metrics.js   @platform-team
.github/         @platform-team
EOF

# trunk にいることを確かめてから push する（層にいたまま実行すると誤った PR にコミットが入る）
[ "$(git branch --show-current)" = "main" ] \
  && git add .github/CODEOWNERS \
  && git commit -m "chore: add CODEOWNERS" \
  && git push origin main
```

> [!NOTE]
> 上のチーム名は例です。実在しないチームを指定すると保護ルールが機能しません。
> 自分のアカウント名（`@your-name`）に置き換えるか、この Step は読むだけにしてください。

**従来の 1 本の大きな PR では**、全チームのオーナーが同じ PR に呼ばれ、
全員の承認が揃うまでマージできませんでした。

**スタックでは**層ごとにオーナーが分かれるので、
`@data-team` は model 層だけ、`@api-team` は api 層だけをレビューします。
承認が揃った層から順に着地できます。

---

## Step 7: CI コストの見積もり

自分のチームでスタックを導入した場合のコストを試算してください。

```
1 スタックあたりの CI 実行回数
  = 層数 × (初回 submit 1 回 + 修正回数)

例: 4 層 × (1 + 3 回の修正) = 16 回の CI 実行
    従来（1 PR）: 1 × (1 + 3) = 4 回
    → 4 倍
```

**削減策:**

1. 重いジョブをスタックメタデータで最上層に限定する（Step 4）
2. `concurrency` グループで、古い実行をキャンセルする
3. 層数を欲張らない（3〜5 層が実用的な上限）
4. 下層の設計を先に固め、修正回数そのものを減らす

`concurrency` の例:

```yaml
concurrency:
  # push など pull_request 以外のイベントでは github.event.pull_request が null になり、
  # グループ名が "ci-" に潰れて無関係な実行どうしが相互キャンセルする。
  # 既存のワークフローへ入れる場合はフォールバックを必ず置くこと。
  group: ci-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true
```

---

## 確認ポイント

- [ ] `branches: [main]` のワークフローが全層で発火することを確認した
- [ ] `github.event.pull_request.stack` の実際の構造をログで確認した
- [ ] 中間層にもブランチ保護が効くことを確認した
- [ ] CODEOWNERS が層ごとに分かれる利点を説明できる
- [ ] 自チームでの CI コスト増を数値で見積もった

---

## つまずきポイント

| 症状                           | 原因と対処                                                                     |
| ------------------------------ | ------------------------------------------------------------------------------ |
| 中間層で CI が走らない         | ワークフローの `on` 条件を確認。`paths` フィルタで層のファイルが対象外の可能性 |
| `pull_request.stack` が `null` | その PR がスタックに属していない。`gh stack view` で確認                       |
| ブランチ保護 API が 403 / 404  | private リポジトリでプランが対応していない。public にするか読むだけにする      |
| CODEOWNERS が効かない          | 指定したチーム / ユーザーが存在しない。リポジトリへのアクセス権も必要          |
| CI がキューで詰まる            | 層数 × 修正回数ぶん走っている。`concurrency` の設定を検討                      |

---

## 振り返り課題

1. `on: pull_request: branches: [main]` のワークフローが、
   `legacy/logger` を base に持つ中間層の PR でも発火するのはなぜか。
2. 単体テストを最上層のみで走らせるとどんな事故が起きるか。
3. スタック導入で CI 時間が 4 倍になった。削減策を優先度順に 3 つ挙げよ。
4. CODEOWNERS の観点で、スタックが従来の PR より有利な点は。

<details>
<summary>解答</summary>

1. GitHub がスタックの最終的な着地先（trunk）を見て発火を判定するため。
   中間層の base が別ブランチでも、そのスタックは最終的に `main` に着地する。
2. 中間層が壊れたまま承認・マージされうる。特に**部分マージ**した瞬間に
   壊れた層が `main` に入り、`main` が壊れる。
3. (a) 重いジョブ（E2E / 性能 / スキャン）を最上層に限定、
   (b) `concurrency` で古い実行をキャンセル、
   (c) 層数を絞る・下層の設計を先に固めて修正回数を減らす。
4. 層ごとにオーナーが分かれるため、各チームは自分の担当層だけをレビューすればよい。
   全チームの承認が揃うのを待たずに、承認された層から順に着地できる。

</details>

---

## 後片付け

この Lab までで、Lab 08 の PR 3 本、ワークフロー、ブランチ保護、CODEOWNERS が残っています。
**カリキュラムを終えたら片付けてください。**

```bash
# 推奨: 練習用リポジトリごと削除する（設定も PR もまとめて消える）
cd "${SPR_HOME:?先にカリキュラムのディレクトリで SPR_HOME を export してください}" \
  && ./scripts/reset-playground.sh
```

復習用にリポジトリを残す場合は、少なくとも次を戻します。

> [!WARNING]
>
> **`gh repo edit` と `gh pr list` は、引数を省略するとカレントディレクトリのリモートを対象にします。**
> 上の手順でカリキュラムのディレクトリへ移動しているため、**そのまま打つと
> 教材を置いているリポジトリの設定を変えてしまいます。** 対象を必ず明示してください。

```bash
TARGET="$(gh api user --jq .login)/${PLAYGROUND_REPO:-stacked-pr-playground}"

# public にしていた場合のみ戻す
gh repo edit "$TARGET" --visibility private --accept-visibility-change-consequences

# 残っている PR を確認して close する
gh pr list --repo "$TARGET" --state open
```

- **ブランチ保護ルール**: Settings → Branches から削除
- **CODEOWNERS**: `.github/CODEOWNERS` を削除
- **ワークフロー**: `.github/workflows/ci.yml` を削除（Actions の実行枠を消費し続けないように）

---

次は [10. 組織へのロールアウト設計](../docs/10-rollout.md) へ。
