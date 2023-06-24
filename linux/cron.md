## cron

```bash
# 基本
cron オプション
-e 編集
-l 表示
-r 削除

# crontanの書式
分 時 日 月 曜日 実行コマンド

* 全ての数字
- 範囲の指定
, リストの指定
/ 数値のよる間隔指定

# 2分おきに日時をログに書き込み
cronta -e
*/2 * * * * /bin/date >> /tmp/datefile

# 設定内容の表示
crontab -l
*/2 * * * * * /bin/date >> /tmp/datefile

ls /var/spool/cron/*
-rw------ admin admin /var/spool/cron/admin

# crontabファイルの削除
cron -r
cron -l
no crontab for admin

# 実行ユーザーの制限
/etc/cron.allow
/etc/cron.deny

cron.allowがある場合、ファイルに記述されているユーザーが利用できる
cron.allowがなくcron.denyがある場合、ファイルに記述されていないユーザーが利用するできる
両方ない場合は全てのユーザーが利用できる

# 設定ファイルから登録(confの末尾は改行が必要)
crontab cron.conf

```
