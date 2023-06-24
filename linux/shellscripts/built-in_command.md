## Null command

```bash
# :は何も処理を行わずに常に終了ステータスとして0を返す(trueを書いても同じ)
# 無限ループ
while : do
	処理
done
```

## printf

```bash
# 書式に基づいて文字列を標準出力に出力する
pfintf 書式文字列 引数1 引数2...

%s 文字列
%d 整数値
%x 16進数値。ただしaからfまでの小文字表記
%X 16進数値。ただしAからFまでの大文字表記
%% %そのもの
```

## set

```bash
# 現在設定されているシェル変数の一覧を表示
set

# シェルのオプションを有効または無効に設定する
set -o verbose #有効化
set +o verbose #無効化

-e errexit 終了ステータスが0以外の場合はシェルを終了する
-u nounset 未定義の変数がある場合はエラーとする
なし pipefail パイプ処理で一つでもエラーがあった場合は終了ステータスが0でない値となる
-n noexec 構文チェック

# 位置パラメータの値を設定する
#!/bin/bash
echo "$1, $2, $3, $4"
set 111 222 333 444
echo "$1, $2, $3, $4"

./set_parameter.sh aaa bbb ccc ddd
aaa, bbb, ccc, ddd
111, 222, 333, 444 # setで置き替わった
```

## trap

```bash
# 現在のプロセスに対して送られたシグナルを捕捉する
trap 処理 シグナル名1 シグナル名2・・・

# Ctrl + Cで終了させるとメッセージを表示
# INT補足後に後続の処理を終了させるにはexitを書く必要がある
trap 'echo receive INT signal!; exit' INT

echo start
sleep 5
echo end

# シグナル一覧を表示
kill -l

1) SIGHUP       2) SIGINT       3) SIGQUIT      4) SIGILL       5) SIGTRAP
 6) SIGABRT      7) SIGBUS       8) SIGFPE       9) SIGKILL     10) SIGUSR1
11) SIGSEGV     12) SIGUSR2     13) SIGPIPE     14) SIGALRM     15) SIGTERM
16) SIGSTKFLT   17) SIGCHLD     18) SIGCONT     19) SIGSTOP     20) SIGTSTP
21) SIGTTIN     22) SIGTTOU     23) SIGURG      24) SIGXCPU     25) SIGXFSZ
26) SIGVTALRM   27) SIGPROF     28) SIGWINCH    29) SIGIO       30) SIGPWR
31) SIGSYS      34) SIGRTMIN    35) SIGRTMIN+1  36) SIGRTMIN+2  37) SIGRTMIN+3
38) SIGRTMIN+4  39) SIGRTMIN+5  40) SIGRTMIN+6  41) SIGRTMIN+7  42) SIGRTMIN+8
43) SIGRTMIN+9  44) SIGRTMIN+10 45) SIGRTMIN+11 46) SIGRTMIN+12 47) SIGRTMIN+13
48) SIGRTMIN+14 49) SIGRTMIN+15 50) SIGRTMAX-14 51) SIGRTMAX-13 52) SIGRTMAX-12
53) SIGRTMAX-11 54) SIGRTMAX-10 55) SIGRTMAX-9  56) SIGRTMAX-8  57) SIGRTMAX-7
58) SIGRTMAX-6  59) SIGRTMAX-5  60) SIGRTMAX-4  61) SIGRTMAX-3  62) SIGRTMAX-2
63) SIGRTMAX-1  64) SIGRTMAX

# 代表的なシグナル。KILL 9 強制終了はtrapできない
HUP 1 プロセスに再起動を通知する
INT 2 プロセスに割り込みを通知する(Ctrl+C)
QUIT 3 プロセスに終了を通知して、コアダンプファイルを作成する(Ctrl+\)
TEAM 15 プロセスに終了を通知する
```

## xargs

```bash
# findコマンドで出力されたファイルリストに対してlsコマンドを実行
find . -type f -name '*.txt' | xargs ls -l

# VPCを並列作成
VPC_CIDR_BLOCK=("10.100.0.0/16" "192.168.100.0/24")
for i in ${VPC_CIDR_BLOCK[@]}; do echo $i; done | xargs -I {} -P 10 echo "{}"
for i in ${VPC_CIDR_BLOCK[@]}; do echo $i; done | xargs -I {} -P 10 aws ec2 create-vpc --region $REGION --cidr-block "{}"
```
