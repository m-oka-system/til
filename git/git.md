# Git

## Configuration

```bash
# ユーザーとEメールアドレスを登録する(~/.gitconfigに書き込まれる)
git config --global user.name "user_name"
git config --global user.email "user_email"

# git configで設定した内容を削除する
git config --global --unset user.name
git config --global --unset user.email

# リモートリポジトリを登録する
git remote add <別名> https://<リポジトリパス>

# 認証情報の入力を省略する
git remote add <別名> https://<username>:<password>@<リポジトリパス>

# リポジトリパスの別名を一覧表示する
git remote -v

# エイリアス
git config --global alias.st status
git config --global alias.ci commit
git config --global alias.co checkout
git config --global alias.br branch

# git log --graphのエイリアス（~/.gitconfigに追記）
g = log --graph --pretty=format:'%x09%C(auto) %h %Cgreen %ar %Creset%x09by"%C(cyan ul)%an%Creset" %x09%C(auto)%s %d'

# 改行コードの自動変換を無効にする
git config --global core.autocrlf false

# 行末のキャリッジリターン(CR)を許容
git config --global core.whitespace cr-at-eol

# この設定をしておけばgit pushするだけでカレントブランチと同名のリモートブランチへpushされる
git config --global push.default current

# pagerを無効にする
git config --global --replace-all core.pager "less -F -X"

# filemode（パーミッション）の変更を無視する
git config --unset core.filemode
git config --global --unset core.filemode
git config --global core.filemode false
```

## Basic

```bash
# 初期化
git init

# ステージングに追加
git add .
git add -A
git add <filename>

# コミット
git commit -m "commit message"

# リモートリポジトリにpush
git push origin main

# 指定したブランチをCloneする
git clone -b <ブランチ名> <リポジトリパス>

# リネームする(mvだと削除→作成の扱いになるがgit mvだとリネームになる)
git mv <before_filename> <alter_filename>

# ファイルを削除する
git rm <filename>
```

## Pull

```bash
# 履歴を取得する
git pull origin main

# git pullは以下の2つを実行するのと同意
git fetch origin
git merge origin/main
```

## Log

```bash
git log
-p        ファイルの中身も表示する
-n 1      直前の1つだけ履歴を表示する
--all     ブランチのログも表示する
--oneline 1行で表示する
--gfaph   各コミットを線で結ぶ
--follow  ファイル名の変更も考慮して表示する
```

## やり直し操作

```bash
# ワークツリーの変更を取り消す(ステージと同期する)
git checkout -- . or <ファイル名> or <ディレクトリ名>

# ワークツリーを元に戻す(前回のコミット状態に戻る)
git checkout .
git checkout HEAD .

# ステージした変更を元に戻す(addを取り消す。ローカルリポジトリの状態と同期させている)
git reset HEAD . or <ファイル名> or <ディレクトリ名>

# 直前のコミットを取り消す
# HEADだけ戻す
git reset --soft HEAD^

# HEADとインデックスを戻す
git reset --mixed HEAD^ # --mixedは省略可能

# HEAD、インデックス、ワーキングツリーを戻す
git reset --hard HEAD^
git reset --hard <commit>

# pushする前に直前のローカルコミットをやり直す、コミットメッセージを修正する(ステージの内容で上書きする)
git commit --amend -m "修正後のコミットメッセージ"
git push -f
※プッシュまで行っている場合はForceオプションで強制上書きする

# コミットを取り消す（取り消しのコミットを作成する）
git revert <コミットのオブジェクト名>
git revert 98bba19
git revert HEAD #直前のコミットを打ち消し

# 複数のコミットを一つにまとめて元に戻す（OLDER_COMMIT^は打ち消すコミットの１個前->戻りたいコミットを指定）
git revert -n OLDER_COMMIT_HASH^..NEWER_COMMIT_HASH
git commit -m "Revert to OLDER_COMMIT_HASH"

-n --no-commit コミットせずステージングする
--no-edit      コミットメッセージを編集しない（即コミット）

#　削除したコミットを復元する
git reflog
git reset --hard <commit>

# 一時的に過去のコミットに戻る
git switch -d <commit>

#　もとのHEADに戻る
git switch -
```

## Branch

```bash
# ブランチ一覧を表示する
git branch

# 新しいブランチを作成する
git branch <ブランチ名>

# ブランチを切り替える
git checkout <ブランチ名>

# 新しいブランチを作成して、かつ、ブランチを切り替える
git checkout -b <ブランチ名>
git switch -c <ブランチ名>

# ブランチをリネームする
git branch -m <before> <aflter>
git branch -M <before> <aflter> # even if target exists

# ローカルでリモートブランチにチェックアウト
git checkout -b staging-workflow origin/staging-workflow

# 指定したブランチを現在のブランチにマージする(通常はmainブランチで実行)
git merge <マージするブランチ名>

# ブランチを削除する(マージしていないと削除不可)
git branch -d <ブランチ名>

# featureブランチをまとめて削除する
git br | grep feature | xargs git br -d

# ブランチを強制削除する
git branch -D <ブランチ名>
```

## Merge

```bash
# 指定したブランチを今いるブランチにマージする
git merge <ブランチ名>

# ブランチを切ってからマージするまでの流れ（ローカル）
git checkout -b feature
echo "Add line to last" >> README.md
git add README.md
git ci -m "update README.md"
git checkout main
git diff main feature
git merge feature
git log
git branch -d feature

# マージの取り消し(コンフリクトした場合など)
git merge --abort
```

## Cherry-pick

```bash
# 特定のコミットを取り込み
git cherry-pick <commit>

# 複数のコミットを一括で取り込み
git cherry-pick <始点の一つ前commit>..<終点のcommit>

# マージコミットを取り込み
git cherry-pick -m 1 <merge_commit>

# 取り消し（コンフリクトした場合など）
git cherry-pick --abort
```

## Diff

```bash
# ワークツリーとインデックスの差分を表示
git diff
git diff -- <filename>

# インデックスとリポジトリの差分を表示
git diff --cached
git diff --staged HEAD

# ワークツリーとリポジトリの差分を表示(git diff + git diff --cache)
git diff HEAD

# ブランチ同士の差分を確認
git diff <base> <compare>

# コミット同士の差分を確認
git diff <commitID> <commitID>
git diff HEAD HEAD^ #HEAD^が1個前、HEAD^^が2個前

# p4mergeを使用する
git config --global diff.tool p4merge
git config --global difftool.p4merge.path /Applications/p4merge.app/Contents/MacOS/p4merge
git config --global difftool.prompt false

git config --global merge.tool p4merge
git config --global mergetool.p4merge.path /Applications/p4merge.app/Contents/MacOS/p4merge
git config --global mergetool.prompt false
git config --global mergetool.keepBackup false
git config --global mergetool.p4merge.keepTemporaries false
git config --global mergetool.p4merge.trustExitCode false

# Meldを使用する
git config --global diff.tool Meld
git config --global difftool.Meld.path /Applications/Meld.app/Contents/MacOS/Meld
git config --global difftool.prompt false

git config --global merge.tool Meld
git config --global mergetool.Meld.path /Applications/Meld.app/Contents/MacOS/Meld
git config --global mergetool.prompt false

# diftoolで比較
git difftool
```

## Tag

```bash
# タグを付与
git tag <tag_name>
git tag <tag_name> <commit_id>
git tag -a <tag_name> -m "<message>"

# タグの一覧を表示
git tag
git tag -l <パターン>

# タグの詳細を表示
git show <tag_name>

# タグを指定してpush
git push origin <tag_name>

# タグをすべてpush
git push origin --tags

# タグを削除
git tag -d <tag_name>

# リモートのタグを削除
git push --delete origin <tag_name>
```

## Stash

```bash
# stashする
git stash
git stash -u # 新規ファイルも含める
git stash save "message" # メッセージをわかりやすくする

# stashした一覧を表示する
git stash list

# stashした内容をワークツリーに戻す
git stash apply # インデックスにあった作業内容もワークツリーに戻る
git stash apply --index # インデックスにあった作業内容はインデックスに戻す

# 退避した作業を元に戻すと同時に、stashのリストから消す
git stash pop apply

# stashから削除する
git stash drop
```

## Rebase

```bash
# マージコミットが作られない（履歴が一直線）
git rebase <ブランチ名>

# コミットをまとめる
git rebase -i <変更後にひとつ前に指すコミットID>
```

## Commit message

```bash
- fix：バグ修正
- hotfix：クリティカルなバグ修正
- add：新規（ファイル）機能追加
- update：機能修正（バグではない）
- change：仕様変更
- clean：整理（リファクタリング等）
- disable：無効化（コメントアウト等）
- remove：削除（ファイル）
- upgrade：バージョンアップ
- revert：変更取り消し

ライト版
- fix：バグ修正
- add：新規（ファイル）機能追加
- update：機能修正（バグではない）
- remove：削除（ファイル）
```

## Git secret

```bash
## インストール
# Mac
brew install git-secrets

git secrets --register-aws --global
git secrets --install ~/.git-templates/git-secrets
git config --global init.templatedir '~/.git-templates/git-secrets'

# Windows
git clone https://github.com/awslabs/git-secrets.git
cd git-secrets
./install.ps1

git secrets --register-aws --global
git secrets --install ~/.git-templates/git-secrets -f
git config --global init.templatedir ~/.git-templates/git-secrets

## 既存リポジトリを保護対象にする
git secrets --install

## コミットエラーを無視する
git commit -m "sample commit" --node-verify


# 設定を削除する
rm .git/hooks/commit-msg
rm .git/hooks/pre-commit
rm .git/hooks/prepare-commit-msg
git config --global --unset-all commit.template
```

## Git の典型的な作業フロー（pull reqest）

```bash
# ベースブランチ(main)にいることを確認
git branch

# ベースブランチがクリーンであることを確認
git status

# ベースブランチを最新の状態にする（リモートブランチと同期）
git pull origin main

# 作業ブランチを作成
git checkout -b refactor/modify_top_page_message

# ソースを修正
# RSpecなどを実行してテスト
# テストコードを修正してエラーが出なくなることを確認

# 変更箇所を確認
git status

# 変更をステージング
git add -A

# 変更をコミット
git commit -m "refactor: Modify top page's message"

# 変更をプッシュ(HEADはカレントブランチと同じ名前のリモートブランチ)
git push origin HEAD

# Githubでpull requestを作成
# レビュアーを登録
# レビュアーはFile changedタブで差分を確認してコードレビュー
# 問題なければ「Review changes」ボタンからApprove(承認)
# mainにマージしてリモートブランチを削除

# ベースブランチに戻って最新化
git checkout main
git pull origin main

# ローカルブランチを削除
git branch -d refactor/modify_top_page_message
```

## SSH 対応

```bash
# キー作成（ED25519）
ssh-keygen -t ed25519 -C ""

# GitHubに公開鍵を登録

# 接続確認
ssh -T git@github.com

# ssh-agentのサービスを自動起動に設定（管理者で実行）
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent
Get-Service ssh-agent

# 秘密鍵をssh-agentに追加
ssh-add $HOME/.ssh/id_ed25519

# 確認
ssh-add -l
```

```bash
# ~/.ssh/config
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

## GitHub の初期コマンド

```bash
echo "# git-practice" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/m-oka-system/git-practice.git
git push -u origin main
```
