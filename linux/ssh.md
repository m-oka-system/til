## キーペアを作成

```bash
ssh-keygen -t rsa -C ""

-t 暗号化方式
   rsa(デフォルト)
   dsa
   ecdsa
   ed25519

-b 鍵のビット数。RSAの場合は 2048 bitがデフォルト
-C コメント。-C "" でコメント削除
-f ファイル名を指定
-m フォーマットを指定(PEM)
-y -f <filename>.pem 秘密鍵を読み込んで公開鍵の内容を出力する

# ed25519で作成
ssh-keygen -t ed25519 -C ""

# ~/.ssh/configにホスト情報を追記
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519

# 公開鍵をコピーしてGithybのSettings -> SSH and GPG keyに登録
pbcopy < ~/.ssh/id_ed25519.pub

# リモート先のサーバに公開鍵を登録
ssh-copy-id -i ~/.ssh/id_rsa.pub azureuser@xxx.xxx.xxx.xxx
```
