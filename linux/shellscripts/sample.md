## 引数を指定するスクリプトで引数の数をチェック

```bash
# Variables
servers="$@"

if [ "$#" -eq 0 ]; then
  echo  "1つ以上の引数を指定してください。"
  exit 1
fi
```

## バックグラウンドで関数を実行して処理終了まで WAIT する

```bash
# function
function okng () {
  if [ "$1" = "ok" ]; then
    sleep 5
    echo "成功しました。"
  elif [ "$1" = "ng" ]; then
    sleep 10
    echo "失敗しました。"
    exit 1
  fi
}

# main
. ./okng.sh

var=("ok" "ng")
for i in ${var[@]}; do
  okng $i &
  pids+=($!)
done

jobs -l
for pid in ${pids[@]}; do
  wait $pid
  if [ $? -ne 0 ]; then
    echo "タイムアウトになったため処理を終了します。"
    jobs=`jobs -p`
    if [ -n "$jobs" ]; then
      kill -9 $jobs
    fi
    exit 1
  fi
done

echo "処理が完了しました。"
echo "続いて処理を行います。"
```

## 数値の合計値を計算する

```bash
#!/usr/bin/env bash

# 名前
#  sum.sh - 数値の計算をする
#
# 書式
#  sum.sh NUMBER...
#
# 説明
#  引数で指定したすべての数値の合計値を標準出力に出力する。
#  指定できる数値は整数(0または負の値も含む)。小数は指定できない。

readonly SCRIPT_NAME=${0##*/}

result=0

# $@は渡された引数すべて
# for number in "$@"; do
  # [[]] の中で =~ を使って拡張正規表現で比較。^-? 先頭に-が0回以上、[0-9]+$ 0-9が末尾までに1回以上

# read を使って標準入力から読み取って計算する
while IFS= read -r number; do
  if [[ ! $number =~ ^-?[0-9]+$ ]]; then
    printf '%s\n' "${SCRIPT_NAME}: '$number': non-integer number"
    1>&2
    exit 1
  fi

  ((result+=number))
done

printf '%s\n' "$result"
```

## 指定したユーザーの情報を出力する

```bash
#!/usr/bin/env bash

# 名前
#  userinfo.sh - 指定したユーザーの情報を出力する
#
# 書式
#  userinfo.sh USER
#
# 説明
#  指定したユーザーのユーザー名、ユーザーID、グループID、
#  ホームディレクトリ、ログインシェルを標準出力に出力する。

readonly SCRIPT_NAME=${0##*/}

user=$1

if [[ -z $user ]]; then
  printf '%s\n' "${SCRIPT_NAME}: missing username" 1>&2
  exit 1
fi

cat /etc/passwd \
  | grep "^${user}:" \
  | {
      IFS=: read -r username password userid groupid \
                      comment homedirectory loginshell

      if [[ $? -ne 0 ]]; then
        printf '%s\n' "${SCRIPT_NAME}: No such user" 1>&2
        exit 2
      fi

      cat <<END
username = $username
userid = $userid
groupid = $groupid
homedirectory = $homedirectory
loginshell = $loginshell
END
}
```

## ログ出力する関数

```bash
#!/bin/bash
readonly LOGFILE="/tmp/${0##*/}.log"

readonly PROCNAME=${0##*/}
function log() {
  local fname=${BASH_SOURCE[1]##*/}
  echo -e "$(date '+%Y-%m-%dT%H:%M:%S') ${PROCNAME} (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $@" | tee -a ${LOGFILE}
}

#!/bin/bash -
# You must set 'LOGFILE'
readonly PROCNAME=${0##*/}
function log() {
  local fname=${BASH_SOURCE[1]##*/}
  echo -e "$(date '+%Y-%m-%dT%H:%M:%S') ${PROCNAME} (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $@" | tee -a ${LOGFILE}
}
```

## ファイル名、パス取得

```bash
# スクリプトのパスを取得
SCRIPT_DIR=$(dirname $0)

# スクリプトのファイル名を取得
SCRIPT_FILE=$(basename $0)
```

## 成功するまで指定回数リトライする

```bash
RetryCount=5
n=0
until [  $n -ge $RegryCount ]; do
  <処理> && break # 成功したら処理を抜ける
  echo "処理に失敗しました。1秒後にリトライします"
  n=$((n+1))
  sleep 1
done
if [ $n -ge $RetryCount ]; then
  echo "処理に失敗しました"
  continue
fi
```
