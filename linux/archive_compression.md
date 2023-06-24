- アーカイブ：複数のファイルやディレクトリをまとめたファイルのこと → tar コマンド
- 圧縮：ファイルサイズを小さくすること → gzip/bzip コマンド

## tar

```bash
# ファイルをアーカイブ
tar cf < アーカイブファイル> <アーカイブ元ファイルパス>
tar cf dir1.tar dir1

--remove-files アーカイブ元を削除する

# アーカイブファイルの内容を表示
tar tf dir1.tar

# アーカイブファイルの展開
tar xf dir1.tar

# フォルダ指定して展開
tar xf dir1.tar -C efs --strip-components 1
-C 展開先フォルダ指定

# オプション
cf アーカイブ
tf アーカイブファイルの内容を確認
xf 展開
v 対象のファイルリストを表示(czf)

```

## 注意点

> 単にファイルコピーするだけでなく、ファイルのパーミッションやオーナー、タイムスタンプなどのファイル属性もそのままアーカイブする。

> ただし、一般ユーザーで tar コマンドを実行する場合には、たとえば、所有者が root でオーナーのみにパーミッションがついているファイルはアーカイブできなかったり、そういったファイルが含まれているアーカイブを展開すると不完全な展開となる。

> 基本的には root 権限で tar コマンドを実行する必要がある。

## gzip

```bash
# 圧縮(圧縮元ファイルは削除される)
gzip <圧縮元ファイル名>
gzip dir1.tar

# 圧縮ファイルを展開(圧縮ファイルは削除される)
gzip -d dir1.tar.gz

# 任意のファイル名で圧縮ファイルを作成
gzip -c ps.txt > ps_test.txt.gz
```

## tar+gzip

```bash
# tar+gz形式のファイルを作成
tar czf dir1.tar.gz dir1

# tar+gz形式のファイルを展開
tar xzf dir1.tar.gz

# パイプを利用してtar+gzipを作成
tar cf - dir1 | gzip -c > dir1.tar.gz

# パイプを利用してtar+gzipを展開
gzip -d -c dir1.tar.gz | tar xf -

# sshでリモートホストのディレクトリを転送
ssh ec2-user@ipaddress 'tar czf - dir1' | tar xzf -

# tar+bzip2形式のファイルを作成
tar cjf dir1.tar.bz2 dir1

# tar+xz形式のファイルを作成
tar cJf dir1.tar.xz dir1

# リモートホストで圧縮してローカルに転送して解答する
ssh aws_admin@RHEL01 'tar czf - dir1' | tar xzf -

```

## bzip2

```bash
bzip2 ps.txt
bzip2 -d ps.txt.bz2
bzip2 -c ps.txt > ps_test.txt.bz2
```

- 圧縮率: xz > bzip2 > gzip
- 圧縮展開の時間: xz < bzip2 < gzip

## zip

```bash
# zip,unzipのインストール
sudo yum install zip unzip
sudo apt-get install zip unzip

# zipファイルを作成
zip -r dir1.zip dir1

# 対象ファイル名を表示せずにzipファイルを作成(-qオプション)
zip -rq dir1.zip dir1

# zipファイルの内容を確認
zipinfo dir1.zip

# zipファイルの展開
unzip dir1.zip
unzip -q dir1.zip

# パスワード付きzipファイルの作成(-eオプション)
zip -er dir1.zip dir1
Enter password:
Verify password:

```
