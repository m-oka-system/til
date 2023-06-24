## ユーザー

```bash
# 追加
useradd -m username
-d ホームディレクトリのパスを指定
-e 失効日
-g 1次グループ
-G 2次グループ
-m ホームディレクトリを作成する
-M ホームディレクトリを作成しない
-s ログインシェルを指定
-u UIDの指定

#　確認
cat /etc/passwd              #ユーザーを全て表示
tail -1 /etc/passwd          #末尾1行を表示
grep cloudadmin /etc/passwd  #ユーザー名を指定して表示
id cloudadmin                #UID、GIDなどを表示

# 所属グループの確認
groups                       #ユーザー名を指定しなければ自分のグループを表示
groups cloudadmin            #ユーザー名を指定

# 更新
usermod
-l 変更後のユーザー名 変更するユーザー名
-d ホームディレクトリを変更
-g 1次グループを変更
-G 2次グループを変更
-s ログインシェルを変更
-u UIDの変更

# 削除
userdel -r username
-r ホームディレクトリを削除

# パスワード変更
passwd
-d パスワードを期限切れにする
-e パスワードを削除する。rootのみ

# stdinオプションを利用（SUSEは利用不可）
echo P@ssw0rd | sudo passwd --stdin username

# chpasswdを利用
echo "username:P@ssw0rd" | chpasswd

# ヒアドキュメントを利用
PW="P@ssw0rd"
passwd username<<EOF
$PW
$PW
EOF

# アカウントのロック
usermod -L root
passwd -l root

# アカウント時の状態確認
passwd -S root
root LK 2009-12-21 -1 -1 -1 -1 (パスワードはロック済み。)

# アカウントのロック解除
usermod -U root
passwd -u root　
```

## パスワード

```bash
# パスワードを設定
passwd root
ユーザー root のパスワードを変更。
新しいパスワード:
新しいパスワードを再入力してください:
passwd: すべての認証トークンが正しく更新できました。
```

## グループ

```bash
# 作成
groupadd groupname
-g グループID(GID)を指定。指定しない場合は+1のものが採番

# 確認
cat /etc/group
grep cloudadmin /etc/group

# 更新
groupmod
-n 変更後グループ名 変更するグループ名
-g グループIDを変更する

# 削除
groupdel groupname

# グループ一覧を表示
cat /etc/group
ec2-user:x:1000:

# ユーザー一覧を表示
cat /etc/passwd
ec2-user:x:1000:1000:EC2 Default User:/home/ec2-user:/bin/bash
```
