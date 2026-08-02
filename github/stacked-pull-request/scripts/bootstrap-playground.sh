#!/usr/bin/env bash
#
# GitHub Stacked Pull Requests ハンズオン用の練習リポジトリを作成する。
#
#   ./scripts/bootstrap-playground.sh
#
# 環境変数で上書きできる:
#   PLAYGROUND_DIR   作成先のローカルディレクトリ (既定: ~/stacked-pr-playground)
#   PLAYGROUND_REPO  GitHub 上のリポジトリ名      (既定: stacked-pr-playground)
#   PLAYGROUND_VIS   公開設定 private|public      (既定: private)
#
set -euo pipefail

PLAYGROUND_DIR="${PLAYGROUND_DIR:-$HOME/stacked-pr-playground}"
PLAYGROUND_REPO="${PLAYGROUND_REPO:-stacked-pr-playground}"
PLAYGROUND_VIS="${PLAYGROUND_VIS:-private}"

info()  { printf '\033[0;34m==>\033[0m %s\n' "$1"; }
warn()  { printf '\033[0;33m[!]\033[0m %s\n' "$1"; }
die()   { printf '\033[0;31m[x]\033[0m %s\n' "$1" >&2; exit 1; }

# 相対パスだと、後段で cd したあとの `git -C "$PLAYGROUND_DIR"` が解決できずに落ちる。
# reset-playground.sh も絶対パスしか受け付けないため、入口で揃えて弾く。
case "$PLAYGROUND_DIR" in
  /*) ;;
  *)  die "PLAYGROUND_DIR は絶対パスで指定してください（現在: '$PLAYGROUND_DIR'）" ;;
esac

# --- 前提チェック ------------------------------------------------------------

info "前提条件を確認します"

command -v git  >/dev/null 2>&1 || die "git が見つかりません"
command -v gh   >/dev/null 2>&1 || die "gh (GitHub CLI) が見つかりません"
# 練習用リポジトリのテストは node --test で動かす。
# Lab 05 の確認ポイントと Lab 09 の CI がこれに依存している。
command -v node >/dev/null 2>&1 \
  || die "node が見つかりません。Node.js 20 以上を入れてください（Lab 05 / Lab 09 が 'node --test' を使います）"

# grep がマッチしないと set -e で無言終了してしまうため、`|| true` で受けてから明示的に検査する。
# preview 期間中に --version の出力形式が変わる可能性を考慮している。
GH_VERSION="$(gh --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
[ -n "$GH_VERSION" ] \
  || die "gh のバージョンを判定できませんでした（'gh --version' の出力形式が想定と異なります）"

GIT_VERSION="$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
[ -n "$GIT_VERSION" ] \
  || die "git のバージョンを判定できませんでした（'git --version' の出力形式が想定と異なります）"

version_ge() {
  # $1 >= $2 なら 0 を返す
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]
}

# gh は警告のみ、git は die にしている。gh-stack 拡張自体は gh 2.0 以上で動作するため
# （公式 CLI リファレンス）、2.90.0 未満でも進める余地を残す。一方 git 2.28 は
# 下の `git init -b` が動く条件そのものなので、満たさなければ先へ進めない。
version_ge "$GH_VERSION" "2.90.0" \
  || warn "gh $GH_VERSION です。2.90.0 以上を推奨します (gh stack が正しく動かない可能性があります)"
version_ge "$GIT_VERSION" "2.28.0" \
  || die "git $GIT_VERSION です。2.28 以上が必要です"

gh auth status >/dev/null 2>&1 || die "gh にログインしていません。'gh auth login' を実行してください"

GH_USER="$(gh api user --jq .login)"
info "認証ユーザー: $GH_USER"

if ! gh extension list | grep -q 'github/gh-stack'; then
  info "gh-stack 拡張をインストールします"
  gh extension install github/gh-stack
else
  info "gh-stack 拡張はインストール済みです"
fi

# --- 確認 --------------------------------------------------------------------

cat <<EOS

  作成内容:
    ローカル   : $PLAYGROUND_DIR
    GitHub     : $GH_USER/$PLAYGROUND_REPO ($PLAYGROUND_VIS)

EOS

if [ -e "$PLAYGROUND_DIR" ]; then
  die "$PLAYGROUND_DIR はすでに存在します。別の場所を指定するか ./scripts/reset-playground.sh を実行してください。
  前回の実行が 'git init' より前で中断していた場合、reset は git リポジトリでないと判断して拒否します。
  そのときは中身を確認したうえで手動で削除してください:
    rm -rf '$PLAYGROUND_DIR'"
fi

if gh repo view "$GH_USER/$PLAYGROUND_REPO" >/dev/null 2>&1; then
  die "GitHub に $GH_USER/$PLAYGROUND_REPO がすでに存在します。別名を指定するか ./scripts/reset-playground.sh を実行してください"
fi

read -r -p "この内容で作成しますか? [y/N] " answer
case "$answer" in
  [yY]|[yY][eE][sS]) ;;
  *) info "中止しました"; exit 0 ;;
esac

# --- ローカルリポジトリの作成 -------------------------------------------------

info "ローカルリポジトリを作成します: $PLAYGROUND_DIR"

mkdir -p "$PLAYGROUND_DIR/src" "$PLAYGROUND_DIR/test"
cd "$PLAYGROUND_DIR"

cat > README.md <<'EOF'
# Stacked PR Playground

GitHub Stacked Pull Requests ハンズオン用の練習リポジトリです。

## これから積む層

| 層 | ブランチ | 内容 |
|----|---------|------|
| 3 | `feat/task-api` | HTTP ハンドラ |
| 2 | `feat/task-store` | インメモリ永続化 |
| 1 | `feat/task-model` | データ構造とバリデーション |
EOF

cat > package.json <<'EOF'
{
  "name": "stacked-pr-playground",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node --test"
  }
}
EOF

cat > src/index.js <<'EOF'
// 各層でここに export を足していきます。
export const VERSION = '0.1.0';
EOF

cat > test/smoke.test.js <<'EOF'
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

// このテストは src/index.js の「中身」には依存しません。
// 各 Lab で index.js の export は何度も書き換わるため、
// 特定の名前を期待すると Lab を進めるたびにテストが壊れます。
const pkg = JSON.parse(
  readFileSync(new URL('../package.json', import.meta.url), 'utf8'),
);

test('package has a version', () => {
  assert.equal(typeof pkg.version, 'string');
});

// 各層が「単体で」成立していることの最低限の確認。
// その層より上の層にしかないファイルを import していると、ここで落ちます。
test('public entry point can be imported', async () => {
  const mod = await import('../src/index.js');
  assert.equal(typeof mod, 'object');
});
EOF

cat > .gitignore <<'EOF'
node_modules/
*.log
EOF

git init -q -b main
git add .
git commit -q -m "chore: bootstrap playground project"

# --- GitHub リポジトリの作成 --------------------------------------------------

info "GitHub にリポジトリを作成して push します"

gh repo create "$PLAYGROUND_REPO" \
  --"$PLAYGROUND_VIS" \
  --source=. \
  --remote=origin \
  --push \
  --description "Playground for the GitHub stacked pull requests hands-on curriculum"

# --- 完了 --------------------------------------------------------------------

cat <<EOS

  セットアップが完了しました。

    cd $PLAYGROUND_DIR
    gh stack view          # スタックがないので exit 2 が返れば正常

  次のステップ: labs/lab01-first-stack.md

EOS

info "動作確認"
git -C "$PLAYGROUND_DIR" status --short --branch
gh repo view "$GH_USER/$PLAYGROUND_REPO" --json nameWithOwner,isPrivate,url --jq \
  '"repo: \(.nameWithOwner)  private: \(.isPrivate)\nurl:  \(.url)"'
