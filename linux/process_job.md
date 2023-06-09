## プロセス

```bash
# プロセスの確認
ps

PID TTY          TIME CMD
 3734 pts/0    00:00:00 sudo
 3735 pts/0    00:00:00 su
 3736 pts/0    00:00:00 bash
 3819 pts/0    00:00:00 ps

# 現在のユーザーが実行中のすべてのプロセスを表示
ps xf

# システムで動作しているすべてのプロセスを表示
ps ax

# オプション
x:psコマンドを実行したユーザーのプロセスをすべて表示
ux:psコマンドを実行したユーザーのプロセスをすべてを、詳細情報を合わせて表示
ax:すべてのユーザーのプロセスを表示
aux:すべてのユーザーのプロセスを、詳細情報を合わせて表示
auxf:すべてのユーザーのプロセスを、詳細情報を合わせてツリー構造で表示
auxww:auxオプションで、コマンドラインが長くターミナルが右端で切れてしまう際に、表示幅を制限せずすべて表示

# プロセスを終了させる
kill %<プロセス番号>
kill -TERM %<プロセス番号>
```

## PID ファイル

```bash
# pidファイルの確認
cat /var/run/nginx.pid
```

## ジョブ

```bash
# ジョブの一覧を表示(プロセスID含む)
jobs -l
[1]-  停止                  man bash
[2]+  停止                  vi ~/.bashrc

# ジョブをフォアグランドにする
fg %<ジョブ番号>

# ジョブをバックグランドにする
bg %<ジョブ番号>

# ジョブを終了させる
kill %<ジョブ番号>

# プロセスを終了させる
kill -[シグナル名またはシグナルID] PID
kill -TERM 100 # PID100を終了
kill -9 200    # PID200を強制終了

# シグナル一覧を表示
kill -l

# 代表的なシグナル
2:INT 割り込み
15:TERM 終了
20:TSTP 停止
9:KILL 強制終了(TERMを受け取れない場合などに使用)

# ジョブのプロセス番号をすべて取得
jobs -p

# ジョブをすべて強制終了
kill -9 `jobs -p`
```
