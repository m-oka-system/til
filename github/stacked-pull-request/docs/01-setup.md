# 01. 環境準備

所要 20 分

---

## 1. 必要なもの

| ツール            | 必要バージョン                          | 確認コマンド     |
| ----------------- | --------------------------------------- | ---------------- |
| GitHub CLI        | **2.90.0 以上を推奨**（最低 2.0）       | `gh --version`   |
| Git               | **2.28 以上**                           | `git --version`  |
| Node.js           | **20 以上**（`node --test` を使うため） | `node --version` |
| GitHub アカウント | push できるリポジトリを作れること       | `gh auth status` |

> [!NOTE]
>
> Node.js は練習用リポジトリのテストを走らせるために使います。
> Lab 05 の確認ポイントと Lab 09 の CI が `node --test` に依存しており、
> **Lab 09 のワークフローは `node-version: '22'` を指定します。**
> 手元も 20 以上（できれば 22）に揃えておくと、CI との差で悩まずに済みます。

> [!NOTE]
>
> `gh stack` は `gh` 2.0 以上で拡張として動作しますが、
> スタック機能の完全な利用には公式クイックスタートが示す **2.90.0 以上**を推奨します。
> 古い `gh` だとサブコマンドが欠けたり、認証スコープが足りずに落ちます。
>
> Git については公式クイックスタートは 2.20 以上としていますが、本教材の
> `bootstrap-playground.sh` が `git init -b`（**Git 2.28** で追加）を使うため、
> ここでは **2.28 以上**を要件としています。

### バージョンが足りない場合

```bash
# macOS (Homebrew)
brew upgrade gh git

# Linux (apt) — GitHub CLI 公式 apt リポジトリを使う
sudo apt update && sudo apt install gh git
```

### 認証

```bash
gh auth login
gh auth status
```

`gh auth status` に `repo` スコープが含まれていることを確認してください。含まれていない場合:

```bash
gh auth refresh -s repo
```

---

## 2. `gh-stack` 拡張のインストール

```bash
gh extension install github/gh-stack
```

インストール確認:

```bash
gh stack --help
```

サブコマンド一覧（`init` / `add` / `view` / `submit` / `sync` / `merge` など）が出れば成功です。

### 更新

preview 中は頻繁に更新されます。挙動がおかしいときはまず更新してください。

```bash
gh extension upgrade github/gh-stack
```

### エイリアスを作る（任意だが強く推奨）

`gh stack` は毎回打つには長いので、短縮エイリアスを作れます。

```bash
gh stack alias          # デフォルトで `gs` が作られる
gh stack alias st       # 名前を指定する場合

gs view                 # 以降 `gh stack view` と同じ
```

外すとき:

```bash
gh stack alias --remove
```

> [!TIP]
> 本教材のコマンド例はすべて `gh stack ...` の完全形で書いています。
> エイリアスを作った人は適宜読み替えてください。

### 配色の調整

ターミナルの背景色によって `gh stack view` の出力が読みにくい場合:

```bash
export GH_STACK_THEME=dark   # auto | light | dark
```

---

## 3. AI コーディングエージェント連携（任意）

`gh stack` の使い方を AI コーディングエージェントに教える **skill** が公式に配布されています。
Claude Code / GitHub Copilot / Cursor / Codex などに入れておくと、
「スタックを 3 層に分けて作って」のような指示から `gh stack` を正しく使ってくれるようになります。

> [!NOTE]
>
> **skill と拡張は別物です。**
> 拡張（`gh extension install`）が `gh stack` コマンド本体、skill はその使い方をエージェントに渡す知識です。
> skill だけ入れてもコマンドは動きません。**2 の拡張インストールが必須**です。

### インストール

```bash
gh skill install github/gh-stack
```

対話モードでインストール先エージェントを選べます。非対話（スクリプトや CI）で入れる場合は明示します。

```bash
gh skill install github/gh-stack gh-stack --agent claude-code --scope user
```

| フラグ    | 既定値           | 説明                                                                          |
| --------- | ---------------- | ----------------------------------------------------------------------------- |
| `--agent` | `github-copilot` | 導入先エージェント。`claude-code` / `cursor` / `codex` / `gemini-cli` ほか    |
| `--scope` | `project`        | `project` はカレントリポジトリ配下、`user` はホーム配下（全プロジェクト共通） |
| `--pin`   | —                | タグや commit SHA を指定して固定する                                          |

バージョン指定がない場合は「最新のタグ付きリリース → 既定ブランチ HEAD」の順に解決されます。

> [!NOTE]
>
> `gh skill` は preview 中のコマンドです。`unknown command` になる場合は `gh` を更新してください
> （`gh` 2.97.0 で動作確認）。

### 確認

```bash
gh skill list
```

```
gh-stack	claude-code	user	github/gh-stack
```

`--agent claude-code --scope user` で入れた場合、実体は `~/.claude/skills/gh-stack/SKILL.md` です。
frontmatter に取得元（`github-repo` / `github-ref` / `github-tree-sha`）が埋め込まれ、これが更新検知に使われます。

### 更新

```bash
gh skill update --all
```

### 中身を確認してから入れたい場合

skill は**エージェントの権限で動く指示文**です。第三者の skill を入れる前には中身を読んでください。

```bash
gh skill preview github/gh-stack gh-stack
```

> [!WARNING]
> GitHub は skill の内容を検証していません（インストール時にも同じ警告が出ます）。
> 公式 org（`github/`）配布のものであっても、更新のたびに差分を確認する運用が安全です。

---

## 4. 練習用リポジトリを作る

本カリキュラムは「タスク管理 API を 3 層に分けて実装する」シナリオで進みます。
以下のスクリプトが、練習用のローカルリポジトリと GitHub 上のリモートリポジトリを作ります。

```bash
./scripts/bootstrap-playground.sh
```

デフォルトでは:

- ローカル: `~/stacked-pr-playground`
- GitHub: `<あなたのアカウント>/stacked-pr-playground`（**private**）
- 初期ブランチ: `main`（trunk として使う）

作成先を変えたい場合:

```bash
PLAYGROUND_DIR=~/work/sp-lab PLAYGROUND_REPO=my-stack-lab ./scripts/bootstrap-playground.sh
```

> [!IMPORTANT]
>
> **作成先を変えた場合は、`PLAYGROUND_DIR` をシェルに残したまま Lab を進めてください。**
> 各 Lab の冒頭は `cd "${PLAYGROUND_DIR:-$HOME/stacked-pr-playground}"` で始まります。
> 設定していないと既定のパスへ移動しようとして失敗します。
>
> 毎回打つのが面倒なら、シェルの設定ファイルに書いておくか、Lab を始める前に 1 度だけ実行します。
>
> ```bash
> export PLAYGROUND_DIR=~/work/sp-lab
> export PLAYGROUND_REPO=my-stack-lab
> ```
>
> `reset-playground.sh` を実行するときも**同じ値**が必要です。値が違うと削除対象を見つけられません。

> [!WARNING]
> このスクリプトは `gh repo create` で **GitHub 上に新しいリポジトリを作成**します。
> 実行前に `gh auth status` でどのアカウントにログインしているか確認してください。
> 業務アカウントで意図せず organization リポジトリを作らないよう注意。

### 手動で作る場合

スクリプトを使わず自分で用意しても構いません。

> [!WARNING]
>
> **既存の実リポジトリを流用しないでください。** 本カリキュラムは force push、
> ブランチ保護の全置換（`gh api -X PUT`）、リポジトリの可視性変更を行います。
> **捨ててよい新規リポジトリ**を用意してください。

必要な条件は次のとおりです。

1. 自分が push できる**新規の**GitHub リポジトリであること（fork ではなく、直接 push できること）
2. `main` ブランチに最低 1 コミットあること
3. ローカルに clone 済みで、`origin` がそのリポジトリを指していること
4. **`src/` と `test/` ディレクトリがあること** — Lab 01 は `cat > src/model.js` から始まり、
   ディレクトリが無いと失敗します（`mkdir` する手順はありません）
5. **`package.json` に `"type": "module"` があること** — 各 Lab は ESM の `import` を使います
6. **リポジトリの説明に `stacked pull requests hands-on` を含めること**
   — `reset-playground.sh` が「本教材の練習用リポジトリか」を判定するのに使います。
   含めないと削除時に毎回警告が出ます

   ```bash
   gh repo edit <owner>/<repo> --description "Playground for the stacked pull requests hands-on curriculum"
   ```

---

## 5. 動作確認

練習用リポジトリのディレクトリで実行します。

```bash
# cd が失敗したまま以降を実行すると、別のリポジトリの状態を見て
# 「確認できた」と誤解する。cd の成功を前提にまとめて実行する。
# （gh stack view は正常でも終了コード 2 を返すので && の途中には置けない）
cd "${PLAYGROUND_DIR:-$HOME/stacked-pr-playground}" && {
  git status                                    # クリーンであること
  gh repo view --json nameWithOwner,isPrivate   # 対象リポジトリの確認
  gh stack view                                 # 「スタックがない」旨のメッセージが出る（正常）
}
```

`gh stack view` は、この時点では**終了コード 2（Not in a stack, or stack not found）**で終わります。これは正常です。

```bash
cd "${PLAYGROUND_DIR:-$HOME/stacked-pr-playground}" && { gh stack view; echo "exit=$?"; }
# → exit=2
```

もし **終了コード 9（Stacked pull requests not enabled）** が返る場合は、
そのリポジトリまたは organization でスタック機能がまだ有効化されていません。
[トラブルシューティング](../reference/troubleshooting.md) の「exit 9」の項を参照してください。

---

## 6. 練習用リポジトリの中身

`bootstrap-playground.sh` は次のファイルを作ります。素朴な Node.js プロジェクトです。

```
stacked-pr-playground/
├── README.md
├── package.json
├── src/
│   └── index.js        # エントリポイント（まだ何もしない）
└── test/
    └── smoke.test.js   # node --test で動く最小テスト
```

このあとの Lab で、ここに次の 3 層を積んでいきます。

| 層  | ブランチ          | 追加するもの                                          |
| --- | ----------------- | ----------------------------------------------------- |
| 1   | `feat/task-model` | `src/model.js` — Task のデータ構造とバリデーション    |
| 2   | `feat/task-store` | `src/store.js` — インメモリの永続化層（model に依存） |
| 3   | `feat/task-api`   | `src/api.js` — HTTP ハンドラ（store に依存）          |

**下の層がないと上の層は動かない**という依存関係が、スタックの題材としてちょうどよい構造です。

---

## 7. やり直したくなったら

Lab の途中で状態が壊れたり、最初からやり直したくなったら:

```bash
./scripts/reset-playground.sh
```

> [!NOTE]
>
> **このスクリプトは、このカリキュラムのディレクトリ（`github/stacked-pull-request/`）から実行します。**
> Lab の作業中は練習用リポジトリにいるため、そのまま打つと `no such file or directory` になります。
>
> 行き来しやすいよう、Lab を始める前にカリキュラムのディレクトリで 1 度だけ控えておくと楽です。
>
> ```bash
> export SPR_HOME=$(pwd)                  # カリキュラムのディレクトリで実行
> "$SPR_HOME/scripts/reset-playground.sh" # どこからでも呼べる
> ```

ローカルの練習用ディレクトリと、GitHub 上のリポジトリを削除してから
`bootstrap-playground.sh` を再実行できる状態に戻します（実行前に確認プロンプトが出ます）。

> [!CAUTION]
>
> `reset-playground.sh` は **GitHub 上のリポジトリを削除**します。
> 惰性で確定させないよう、確認プロンプトでは**表示された `owner/repo` の入力**を求めます。
> スクリプト側でも削除対象を機械的に検証しますが（`origin` が対象と一致するか等）、
> 表示された対象を必ず目で確かめてください。
> リポジトリ削除には `delete_repo` スコープが必要です（`gh auth refresh -s delete_repo`）。

---

## チェックリスト

次に進む前に、すべて満たしていることを確認してください。

- [ ] `gh --version` が 2.90.0 以上（2.0〜2.89 でも動きますが、未検証の差異が出ることがあります）
- [ ] `git --version` が 2.28 以上
- [ ] `gh auth status` が成功し、`repo` スコープがある
- [ ] `gh auth status` に `workflow` スコープがある（Lab 09 でワークフローを push するのに必要）
- [ ] `gh stack --help` でサブコマンド一覧が表示される
- [ ] （任意）skill を入れた場合、`gh skill list` に `gh-stack` が出る
- [ ] 練習用リポジトリを clone したディレクトリにいて、`git status` がクリーン
- [ ] `gh stack view` が終了コード 2（≠ 9）で終わる

---

次は [Lab 01: 最初のスタックを作る](../labs/lab01-first-stack.md) へ。
