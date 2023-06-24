## if

```bash
# if分の構造
if <コマンド1>; then
	<コマンド1>の結果が真である場合の処理
elif <コマンド2>; then
	<コマンド2>の結果が真である場合の処理
else
	上記の結果がすべて偽である場合の処理
fi

# testコマンド(次の2文は同じ意味)
if [ "$1" = "bin" ]; then
test "$1" = "bin"; then

# 文字列に関する評価演算子
str1 = str2 等しい
str1 != str2 等しくない
-n str1 空文字ではない
-z str1 空文字である

# 整数に関する評価演算子
int1 -eq int2 等しい
int1 -ne int2 等しくない
int1 -lt int2 int1がint2より小さい
int1 -le int2 int1がint2以下
int1 -gt int2 int1がint2より大きい
int1 -ge int2 int1がint2以上

# ファイル属性に関する評価演算子
-a file fileが存在する(-eと同じ)
-e file fileが存在する(-aと同じ)
-d file fileが存在し、ディレクトリである
-f file fileが存在し、通常のファイルである
-h file fileが存在、シンボリックリンクである
-L file fileが存在、シンボリックリンクである(-hと同じ)
-r file fileが存在し、読み取りパーミッションが与えられている
-w file fileが存在し、書き込みパーミッションが与えられている
-x file fileが存在し、実行パーミッションが与えられている
file1 -nt file2 file1の変更時刻がfile2より新しい
file1 -ot file2 file1の変更時刻がfile2より古い

# 結合演算子
条件式1 -a 条件式2　AND条件 (-aの代わりに&&と記述することもできる)
条件式1 -o 条件式2　OR条件 (-oの代わりに||と記述することもできる)
! 条件式 NOT条件
() 条件式をグループ化する

# OR演算子の||  Command1が失敗したらCommand2を実行
rm file1 || echo "Error - Cannot remove file"

# 次と同じ意味
if command1; then
  : #何もしない
else
  command2
fi

# []で判定
var=true
if [ $var = true ]; then
    echo "true"
else
    echo "false"
fi

# "${}"で判定
var=true
if "${var}"; then
    echo "true"
else
    echo "false"
fi

# 処理の結果で分岐(if)
if [ $? -eq 0 ]; then echo TRUE; else echo FALSE; fi
#or
[ $? -eq 0 ] && echo TRUE || echo FALSE

# 変数がNULLの場合は注意
if [ -n $var ]; then
	echo "処理"
else
  echo "varを入力してください"
fi

# 変数が空かどうかを判定（任意の一文字 x を使って判定）
if [ x = x$var ]; then
	echo "変数の取得に失敗しました。処理を終了します。"
  exit 1
fi

# 三項演算子
test $OS = "Linux" && UserData="userdata-linux.sh" || UserData="userdata-windows.sh"

# [[]]を使うと[]の内側に&&,||を使うことができる、単語分割されない
# [[]]は条件を評価するための専用の構文（[はtestコマンド）
if [[ $x -gt 3 && $x -lt 7 ]]; then
	echo 'x > 3 and x < 7'
else
	echo 'x <= 3 or x >= 7'
fi

# ==、!=の右辺の記号はパス名展開されるが、その他はパス名展開されない
str1=xyz
if [[ $str1 == x* ]]; then # マッチするのでYESと表示
	echo YES
else
	echo NO
fi

# ifの判定方法
# https://sousaku-memo.net/php-system/1817
数値判定するとき: (( ))
文字列判定するとき: [[ ]]
終了ステータスを判定するとき: 括弧不要

# 変数入力済みチェック
if [[ -z "$dnsName" || -z "$gitUserName" || -z "$gitUserEmail" ]]; then
  echo "未定義の変数があります。変数：dnsName、gitUserName、gitUserEmailの値を定義してください。"
  exit 1
fi
```

## for

```bash
for ((i=0; i < ${#domainNames[*]}; i++)); do
	XXX
done

for i in ${domainNames[@]}; do
	XXX
done


# 0001.txtからの連番ファイルを作成する
for i in $(seq 1 5); do
	touch "000${i}.txt"
done

# 与えられた引数に対して処理を行う
for i in "$@"; do
	echo $i
done

# breakとcontinu
for i in {1..9}; do
	if [[ $i -eq 3 ]]; then
		continue
	elif [[ $i -eq 5 ]]; then
		break
	fi
	echo $i
done
# 3の時は次の繰り返しに移行。5の時はループを抜ける
1
2
4

# 値を配列で指定する
array=()
declare -a array=(0 1 2 3 4 5 6 7 8 9)
for i in ${array[@]}; do
    echo $i
done

# 値をファイルで指定する
for i in $(cat number.txt); do
    echo $i
done

# 算術式を使用
declare -a array=(0 1 2 3 4 5 6 7 8 9)
for ((i=0; i < ${#array[*]}; i++)); do
    echo $i
done

# スペース区切りの文字列を配列に格納
str="ubuntu debian redhat suse"
A=$(echo {D..Z})
# 配列に格納
ary=(`echo $str`)
alph=(`echo $A`)
# 表示
for i in `seq 1 ${#ary[@]}`
do
  echo "${ary[$i-1]}"_"${alph[$i-1]}"
done
```

## while

```bash
# while分の構造
i=1
while [ "$i" -le 10 ]
do
	echo $i
	i=$((i + 2))
done

i=1
while [ "$status" != "completed" ]
do
	sleep 1m
	status=$()
	if [ $i -gt 60 ]; then
		echo "time out"
		exit 1
	fi
	i=$((i + 1))
done
```

## select

```bash
# select文の構造
select 変数 in リスト
do
	処理
done

# 3つの中から選択
select name in "apple" "banana" "orange"
do
	echo "You selected" $name
done

1) apple
2) banana
3) orange
#? 2
You selected banana
```
