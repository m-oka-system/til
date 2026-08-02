#!/usr/bin/env bash
#
# ハンズオン用の練習リポジトリを削除して、やり直せる状態に戻す。
#
#   ./scripts/reset-playground.sh
#
# 環境変数で上書きできる（bootstrap-playground.sh と同じ値を指定すること）:
#   PLAYGROUND_DIR   削除するローカルディレクトリ (既定: ~/stacked-pr-playground)
#   PLAYGROUND_REPO  削除する GitHub リポジトリ名 (既定: stacked-pr-playground)
#
# 注意: GitHub 上のリポジトリを削除します。削除には delete_repo スコープが必要です。
#       gh auth refresh -s delete_repo
#
set -euo pipefail

PLAYGROUND_DIR="${PLAYGROUND_DIR:-$HOME/stacked-pr-playground}"
PLAYGROUND_REPO="${PLAYGROUND_REPO:-stacked-pr-playground}"

info() { printf '\033[0;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[0;33m[!]\033[0m %s\n' "$1"; }
die()  { printf '\033[0;31m[x]\033[0m %s\n' "$1" >&2; exit 1; }

command -v gh >/dev/null 2>&1 || die "gh (GitHub CLI) が見つかりません"
gh auth status >/dev/null 2>&1 || die "gh にログインしていません"

GH_USER="$(gh api user --jq .login)"
TARGET_REPO="$GH_USER/$PLAYGROUND_REPO"

# --- ヘルパー ------------------------------------------------------------------
#
# rm -rf と gh repo delete の対象を目視確認だけに委ねない。誤った PLAYGROUND_DIR /
# PLAYGROUND_REPO を渡されたときに業務用のものを消さないよう、機械的に確かめる。

# リモート URL を owner/repo へ正規化する。
#   git@github.com:owner/repo.git      -> owner/repo
#   https://github.com/owner/repo.git  -> owner/repo
normalize_repo() {
  # 末尾の .git を落としたうえで、最後の 2 セグメント（owner/repo）だけを取り出す。
  printf '%s' "$1" | sed -E 's#\.git$##; s#.*[:/]([^/]+/[^/]+)$#\1#'
}

# リモート URL からホスト名だけを取り出す。
# 部分一致だと 'evil-github.com' や 'evil.example/github.com/...' を通すため、
# ホストを切り出して完全一致で判定する。
normalize_host() {
  printf '%s' "$1" | sed -E 's#^[a-zA-Z][a-zA-Z0-9+.-]*://##; s#^[^@/]*@##; s#[:/].*$##'
}

# bootstrap が作った練習用リポジトリかどうかを、生成物の中身から判定する。
# （README.md の見出しと package.json の name は bootstrap が固定文字列で書き込む。
#   Lab 04 と Lab 06 は README へ追記するだけなので、コース途中でも壊れない）
looks_like_playground() {
  grep -q '^# Stacked PR Playground' "$1/README.md" 2>/dev/null \
    || grep -q '"name": *"stacked-pr-playground"' "$1/package.json" 2>/dev/null
}

# --- 削除対象の把握 -------------------------------------------------------------

LOCAL_EXISTS="no"
[ -d "$PLAYGROUND_DIR" ] && LOCAL_EXISTS="yes"

# リモートの存在確認。「見つからない」と「確認できない」を区別する。
# ネットワーク断や権限不足を「存在しない」と誤解すると、ローカルだけ消して
# リモートが残り、次回 bootstrap が止まって復帰できなくなる。
REMOTE_EXISTS="no"
if REMOTE_INFO="$(gh api "repos/$TARGET_REPO" --jq '.full_name' 2>&1)"; then
  REMOTE_EXISTS="yes"
else
  case "$REMOTE_INFO" in
    *"Not Found"*|*"404"*) REMOTE_EXISTS="no" ;;
    *) die "GitHub 上の状態を確認できませんでした。ネットワークと 'gh auth status' を確認してください。
    $REMOTE_INFO" ;;
  esac
fi

# --- 削除対象の妥当性検証 -----------------------------------------------------

case "$PLAYGROUND_DIR" in
  /*) ;;
  *)  die "PLAYGROUND_DIR は絶対パスで指定してください（現在: '$PLAYGROUND_DIR'）" ;;
esac

# 文字列のまま比較すると '$HOME//' や '$HOME/.' がホーム判定をすり抜ける。
# 実体パスへ正規化してから判定する。
if [ -d "$PLAYGROUND_DIR" ]; then
  RESOLVED_DIR="$(cd -P "$PLAYGROUND_DIR" 2>/dev/null && pwd -P)" \
    || die "PLAYGROUND_DIR へ移動できません: $PLAYGROUND_DIR"
else
  RESOLVED_DIR="$PLAYGROUND_DIR"
fi

# 比較相手の $HOME も同じ方法で正規化する。
# 片側だけ正規化すると、$HOME 自体がシンボリックリンクの環境
# （/home/user -> /mnt/... のような NFS ホームなど）で一致せず素通りする。
HOME_RESOLVED="$(cd -P "$HOME" 2>/dev/null && pwd -P || printf '%s' "$HOME")"

case "$RESOLVED_DIR" in
  "$HOME_RESOLVED"|"$HOME"|/) die "PLAYGROUND_DIR がホームディレクトリまたはルートを指しています: $PLAYGROUND_DIR（実体: $RESOLVED_DIR）" ;;
esac

# 以降は正規化後のパスで扱う（rm -rf の対象も同じ）
PLAYGROUND_DIR="$RESOLVED_DIR"

LOCAL_ORPHAN="no"
if [ "$LOCAL_EXISTS" = "yes" ]; then
  [ -d "$PLAYGROUND_DIR/.git" ] \
    || die "$PLAYGROUND_DIR は git リポジトリではありません。練習用リポジトリではない可能性があります"

  ACTUAL_ORIGIN="$(git -C "$PLAYGROUND_DIR" remote get-url origin 2>/dev/null || true)"

  if [ -z "$ACTUAL_ORIGIN" ]; then
    # origin が無いのは「bootstrap が push の前に中断した」ケース。
    # ここで拒否すると復帰する手段が無くなるので通すが、
    # 本教材の生成物であることだけは必ず確かめる（無条件に通すと任意のローカル
    # リポジトリを削除できてしまう）。
    looks_like_playground "$PLAYGROUND_DIR" \
      || die "$PLAYGROUND_DIR には origin が無く、本教材が作成したディレクトリにも見えません。
  （README.md の見出しと package.json の name のどちらも一致しませんでした）
  練習用リポジトリのパスを指しているか確認してください。意図した対象なら手動で削除してください"
    LOCAL_ORPHAN="yes"
  else
    ACTUAL_HOST="$(normalize_host "$ACTUAL_ORIGIN")"
    [ "$ACTUAL_HOST" = "github.com" ] \
      || die "origin のホストが github.com ではありません: $ACTUAL_ORIGIN（host: $ACTUAL_HOST）"

    ACTUAL_REPO="$(normalize_repo "$ACTUAL_ORIGIN")"
    [ "$ACTUAL_REPO" = "$TARGET_REPO" ] || die "origin が削除対象と一致しません。
    削除しようとした対象 : $TARGET_REPO
    実際の origin        : $ACTUAL_ORIGIN（= $ACTUAL_REPO）
  PLAYGROUND_DIR と PLAYGROUND_REPO が bootstrap 時と同じ値か確認してください"
  fi

  # origin の一致だけでは守りとして弱い。TARGET_REPO は PLAYGROUND_REPO から組み立てており、
  # 読者が両方の環境変数を自分のリポジトリへ向ければ自己参照的に必ず一致してしまう。
  # 中身のマーカーも見て、一致しなければ確認の強度を上げる。
  looks_like_playground "$PLAYGROUND_DIR" && LOCAL_IS_PLAYGROUND="yes" || LOCAL_IS_PLAYGROUND="no"
fi

# リモート側の検証。ローカルが無い場合、削除対象は $PLAYGROUND_REPO だけで決まる。
# bootstrap が付ける description をマーカーとして扱う。
REMOTE_IS_PLAYGROUND="unknown"
REMOTE_DESC=""
if [ "$REMOTE_EXISTS" = "yes" ]; then
  REMOTE_DESC="$(gh repo view "$TARGET_REPO" --json description --jq '.description // ""' 2>/dev/null || true)"
  case "$REMOTE_DESC" in
    *"stacked pull requests hands-on"*) REMOTE_IS_PLAYGROUND="yes" ;;
    *) REMOTE_IS_PLAYGROUND="no" ;;
  esac
fi

if [ "$LOCAL_EXISTS" = "no" ] && [ "$REMOTE_EXISTS" = "no" ]; then
  info "削除対象がありません。すでにクリーンな状態です"
  exit 0
fi

# --- 確認 ----------------------------------------------------------------------

warn "以下を削除します。元に戻せません。"
cat <<EOS

    ローカルディレクトリ : $PLAYGROUND_DIR            [存在: $LOCAL_EXISTS]
    GitHub リポジトリ    : $TARGET_REPO   [存在: $REMOTE_EXISTS]

EOS

if [ "$LOCAL_ORPHAN" = "yes" ]; then
  warn "ローカルは origin 未設定です（bootstrap の中断跡と判断しました）"
fi

# bootstrap の生成物に見えない場合は警告する（手動で作った読者もここに来るので die はしない）。
if [ "$REMOTE_EXISTS" = "yes" ] && [ "$REMOTE_IS_PLAYGROUND" = "no" ]; then
  warn "GitHub 上の $TARGET_REPO に、bootstrap が付ける説明文が見つかりませんでした。"
  warn "  実際の説明文: '${REMOTE_DESC:-（空）}'"
  warn ""
fi

if [ "${LOCAL_IS_PLAYGROUND:-unknown}" = "no" ]; then
  warn "$PLAYGROUND_DIR は bootstrap の生成物に見えません。"
  warn "  （README.md の見出しと package.json の name のどちらも一致しませんでした）"
  warn ""
fi

if [ "${LOCAL_IS_PLAYGROUND:-unknown}" = "no" ] || [ "$REMOTE_IS_PLAYGROUND" = "no" ]; then
  warn "手動で作った練習用リポジトリならこの警告は想定内です。"
  warn "そうでなければ業務用リポジトリの可能性があります。中身を確認してから進めてください:"
  warn "  https://github.com/$TARGET_REPO"
  warn ""
fi

# 惰性入力を避けるため、プロンプト自身には答えを書かない。
# 上の一覧に出した「GitHub リポジトリ」の値をそのまま入力させる。
read -r -p "削除する場合は、上に表示された GitHub リポジトリを owner/repo の形で入力してください: " answer
[ "$answer" = "$TARGET_REPO" ] || { info "中止しました"; exit 1; }

# --- リモートの削除 -----------------------------------------------------------

if [ "$REMOTE_EXISTS" = "yes" ]; then
  info "GitHub リポジトリを削除します: $TARGET_REPO"
  # リモートの削除に失敗したらローカルを消さずに終了する。
  # 先にローカルだけ消すと、次回 bootstrap が「GitHub 上に既に存在します」で止まり、
  # 手動でブラウザから消すまで復帰できなくなる。
  if ! gh repo delete "$TARGET_REPO" --yes 2>/dev/null; then
    warn "GitHub リポジトリの削除に失敗しました。delete_repo スコープが必要です:"
    warn "  gh auth refresh -s delete_repo"
    warn ""
    warn "ローカルディレクトリは削除せずに残しました:"
    warn "  $PLAYGROUND_DIR"
    warn "スコープを追加してからもう一度実行するか、ブラウザで削除してください:"
    warn "  https://github.com/$TARGET_REPO/settings"
    die "リセットを中止しました"
  fi
fi

# --- ローカルの削除 -----------------------------------------------------------

if [ "$LOCAL_EXISTS" = "yes" ]; then
  info "ローカルディレクトリを削除します: $PLAYGROUND_DIR"
  rm -rf "$PLAYGROUND_DIR"
fi

cat <<EOS

  リセットが完了しました。次のコマンドで作り直せます。

    ./scripts/bootstrap-playground.sh

EOS
