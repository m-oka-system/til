## パーミッション

```bash
# 例
ls -l /bin/cat
-rwxr-xr-x. 1 root root 54048 /bin/cat

# 一文字目はファイルタイプ
-:ファイル
d:ディレクトリ
l:シンボリックリンク

# 二文字目から三文字ずつはパーミッション
1ブロック目:オーナー
2ブロック目:グループ
3ブロック目:その他のユーザー

# パーミッションの記号と意味(ファイル)
r:読み取り
w:書き込み
x:実行

# パーミッションの記号と意味(ディレクトリ)
r:ディレクトリに含まれるファイル一覧の取得
w:ディレクトリの下にあるファイル・ディレクトリの作成・削除
x:ディレクトリをカレントディレクトリにする

※ファイルの削除ができるかどうかはディレクトリのパーミッションで決まり、
　ファイル自身のパーミッションは関係ない
```

## ファイルモード変更

```bash
# file.txtに権限をする
# シンボルモード(相対的指定)
chmod u+w file.txt #オーナーの書き込み権限を追加

# 数値モード(絶対指定)
chomod 755 file.txt

# 一文字目の記号の意味
u:オーナー
g:グループ
o:その他のユーザー
a:ugoすべて

# 二文字目の記号の意味
+:権限を追加
-:権限を禁止
=:指定した権限と等しくする

# 数値モードでのパーミッションの表現
r:4
w:2
x:1
rwxrwxrwx --> 777
rwxr-xr-x --> 755
r-------- --> 400
```

## スーパーユーザー

```bash
# スーパーユーザーに切り替え(環境変数、カレントディレクトリを引き継ぐ)
$ su
パスワード:
exit
$

# スーパーユーザーの環境に初期化して切り替え
su -

# スーパーユーザーとしてコマンドを実行
sudo 実行したいコマンド
[sudo] password for ログインユーザー名:ログインしているユーザーのパスワードを入力

# ユーザーにsudoを許可するかどうかは/etc/sudoersで管理
# <ユーザー名> <マシン名>=(<権限>) <コマンド>
%wheel ALL=(ALL) ALL

# /etc/sudoersはvisudoで編集すること(通常はvimが起動する)
# 文法に誤りがある場合はエラーが表示される
sudo su
visudo

# スクリプトでsudoersへ追加
USER_NAME="aws_admin"
echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" | EDITOR='tee -a' visudo >/dev/null
```
