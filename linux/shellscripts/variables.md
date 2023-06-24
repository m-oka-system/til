## 変数の宣言

```bash
# シェル変数
abc=123

# シェル変数の一覧を表示
set

# シェル変数を削除
unset abc

# 変数の型を明示的に宣言
declare -i num=1

r 読み取り専用
i:整数
a:配列
A:連想配列

# 環境変数
export xyz=234

# 環境変数の一覧を表示
env
printenv

# 環境変数を削除
unset xyz

# 整数の変数は$をつけなくてよい
x=5
y=8
declare -i sum=x+y # $x+$yとしなくてよい

# 変数の文字数を出力
echo ${#abc}

# 算術式展開
i=$((i + 1))

# 変数の値が空(NULL)であればデフォルト値を代入する
: ${変数:=デフォルト値}
: ${REGION:="ap-northeast-1"}
```

## 特殊なシェル変数

```bash
$HOME   :ホームディレクトリのフルパス
$PWD    :カレントディレクトリ(pwdと同じ)
$OLDPWD :１つ前のディレクトリ
$SHELL  :ログインシェルのフルパス
$BASH   :現在動作しているBashコマンドのフルパス
$BASH_VERSION :Bashのバージョン
$LINENO :現在実行しているスクリプトの行番号
$LANG   :ロケール
$PATH   :コマンドを探すディレクトリを指定するための変数
```

## 位置パラメータ

```bash
# 位置パラメータ
$0 実行時のシェルスクリプト名
$1 第1引数
$2 第2引数
$@ 全ての位置パラメータ。ダブルクオートで囲むとそれぞれの位置パラメータが""で囲まれる
${@:2}　2つ目以降のパラメータ
$* 全ての位置パラメータ。ダブルクオートで囲むと全体が1つの文字列として""で囲まれる
```

## 特殊パラメータ

```bash
$# 引数の個数
$? 終了ステータスの値
$$ 現在のプロセスID
$! 最後に実行したバックグランドコマンドのプロセスID

${0##*/} ファイル名
${BASH_SOURCE[1]##*/}　ファイル名
${BASH_LINENO[0]}　行番号
${FUNCNAME[0]}　自分の関数名
${FUNCNAME[1]}　呼び出し元関数名

# 終了ステータス
echo $?
0

# 終了ステータスが0の時(正常終了した時)にコマンド2を実行
コマンド1 && コマンド2

# 終了ステータスが0以外の時(正常終了しなかった時)にコマンド2を実行
コマンド1 || コマンド2
```

## 配列

```bash
# 配列を変数に入れる
declare -a array=(0 1 2 3 4 5 6 7 8 9)

# 配列の要素をすべて参照する
echo ${array[@]}

# 配列のN番目の要素を参照する
echo ${array[n]}

# 配列の要素をカウントする
echo ${#array[@]}
echo ${#array[*]}

# 配列に要素を追加する
array=(-2 -1 "${array}@")
array=("${array[@]}" 10 11)
array+=(12 13)

# インデックス一覧を取得(配列の一部が空の場合に、値を持つインデックス一覧を取得するために利用)
echo ${!array[@]}

# 配列の要素を削除する
unset array[1] # 削除された箇所は未設定になる
```

## 連想配列（辞書）

```bash
# 配列を変数に入れる(declareでの宣言は必須)
declare -A user=([id]=5 [name]=yamada)

# 配列の要素をすべて参照する
echo ${array[@]}

# 配列の要素を参照する
echo ${user[id]} # key
echo ${user[name]} # value

# 配列の要素をカウントする
echo ${#user[@]}

# 配列に要素を追加する
user[country]=Japan

# Key一覧を取得
echo ${!user[@]}

# 配列の要素を削除する
unset user[name]
```