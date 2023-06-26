## wc

```bash
# バイト数・単語数・行数を数える
# 行数、単語数、バイト数、ファイル名の順で出力される
wc /etc/passwd
25   41 1238 /etc/passwd

# wc コマンドのオプション
-l 行数を表示
-w 単語数を表示
-c バイト数を表示

# ルートディレクトリ直下のファイル、ディレクトリの数をカウント
ls / | wc -l
```

## sort

```bash
# psコマンドの結果をコマンド名でソート
ps x | soft -k 5

-k 並び替えをするフィールドを指定
-n 数値とみなして並び替え
-r 降順に並び替え
-u　重複行を一度しか表示しない(uniqと同じ効果)
```

## uniq (連続した重複行を除外)

```bash
# file3から重複(sortが必要)
sort file3 | uniq

#重複行数を数えて多い順に出力
soft file3 | uniq -c | sort -rn
```

## cut

```bash
# 入力の一部を切り出して出力する
cut -d <区切り文字> -f <フィールド番号> <ファイル名>

# file.csvをカンマで区切って3番目のフィールドを出力
cut -d , -f 3 file.csv
```

## tr

```bash
# 入力の文字を置き換える
tr <置換前の文字> <置換後の文字>

# /etc/passwdの:を,に置換する
cat /etc/passwd | tr : ,

# 小文字を大文字へ置換する(※1文字単位の文字置換であることに注意)
cat /etc/passwd | tr a-z A-z

# 文字の削除
tr -d <削除文字>

# 改行コードを削除
cat /etc/passwd | tr -d "\\n"
```

## less

```bash
# 1画面ずつ表示する
less /etc/apt/sources.list

k 上に1行スクロール
j 下に1行スクロール
b 上に一画面スクロール
f 下に一画面スクロール
u 上に半画面スクロール
d 下に半画面スクロール
g テキストの先頭に移動
G テキストの末尾に移動
/ 文字列を検索
n 下方向に検索を繰り返す
N 上方向に検索を繰り返す
q 終了する
```

## tail

```bash
# 末尾の10行を表示(デフォルト)
 tail /etc/passwd

# 末尾の1行を表示
tail -n 1 /etc/passwd

# ファイルをリアルタイムでモニタする
tail -f <ファイル名>
```

## diff

```bash
# ユニファイド形式で差分を出力
diff -u <比較元のファイル> <比較先のファイル>
```

## sed

```bash
# sedの基本構文
# オプションはアドrすとコマンドを組み合わせた文字列
sed [オプション] <スクリプト> <対象ファイル>

-r 拡張正規表現を使用する
-e スクリプトを指定する
-i ファイルを編集して上書き保存する
-i.bak 編集前のファイルは「*.bak」でバックアップして、元ファイルを編集して上書き保存する

# 1行目を削除する
sed 1d drink.txt

# 1行目とコメント行を削除する
cat server-list.csv | sed 1d | sed '/^#/d'

# 2～5行目を削除する
sed 2,5d drink.txt

# 3～最終行を削除する(メタ文字を利用するのでシングルクォートで括る)
sed '3,$d' drink.txt

# 特定文字列の次の行に追加する(¥a)
sed '/main/a¥dns=none'

# 最終行に追加する
sed '$a<word>'
sed '$a<word1>\n<word2>' # 改行して2行追加

example)
sed -i".org" -e '/\[main\]/a\dns=none' /etc/NetworkManager/NetworkManager.conf

# 先頭がBで始まる行を削除(正規表現を利用する場合は/スラッシュで囲む。\バックスラッシュではない)
sed /^B/d drink.txt

# 1行目を表示する(-n はパターンスペースを出力しない)
sed -n 1p drink.txt

# 置換する
sed s/置換前文字列/置換後文字列/フラグ

# 特定のキーワードに合致した行を置換する
sed /keyward/s/置換前文字列/置換後文字列/

# すべてのBeerをWhineに置換(gフラグ)
sed s/Beer/Whisky/g drink.txt

# Bで始まりrで終わる文字列をWhiskyに置換
sed 's/B.*r/Whisky/g' drink.txt

# !を削除(置換後文字列を指定しない)
sed 's/!//g' drink.txt

# 置換が発生した行だけを表示する(pフラグで置換が発生した場合に出力)
sed -n 's/!//gp' drink.txt

# Bで始まりeが1回以上繰り返されている文字列をWhiskyに置換(\でエスケープ or -rオプションを指定)
sed 's/Be\+r/Whisky/' drink.txt #基本正規表現
sed -r 's/Be+r/Whisky/' drink.txt #拡張正規表現

# マッチした文字列を置換後の結果に埋め込む(後方参照)
sed 's/My \(.*\)/--\1--/' drink.txt
My Vodka
My Wine
  ↓
--Vodka--
--Wine--

sed 's/My \(.*\)/_&/' drink.txt # &は置換後の文字列
My Vodka
My Wine
  ↓
_My Vodka
_My Wine

# 1～3行目を置換する
sed '1,3s/Beer/Whisky/g' drink.txt

# Beerを/Beer/に置換
sed 's/Beer/\/Beer\//g' drink.txt

# 区切り文字を/から%に変更して置換(エスケープが不要になる)
sed 's%Beer%/Beer/%g' drink.txt
```

## awk

```bash
# 基本構文
awk 'パターン {  アクション }' ファイル

$0 行全体
$n n番目の値
$NF 末尾の値

#lsコマンドの結果から5列目と9列目を表示
ls -l /usr/bin | awk '{print $5,$9}'

# 一番最後のフィールドと、その1つ前のフィールドを表示(NFはフィールド数が代入されている変数)
ls -l /usr/bin | awk '{print $(NF-1),$NF}'

# 9番目のフィールド(ファイル名)がcpで始まる行のみをフィルタして表示
# awk フィールド ~(チルダ) /正規表現/ の形で指定
ls -l /usr/bin | awk '$9 ~ /^cp/ {print $5,$9}'

# アクションを省略した場合はすべてのレコードを表示(全レコードは$0)
awk '$9 ~ /^cp/' #アクションを省略
awk '$9 ~ /^cp/ {print}' #アクションの引数を省略
awk '$9 ~ /^cp/ {print $0}' #省略していない

# 区切り文字をカンマに指定
awk -F, '{print $1,$2,$3}' score.csv

# スコアの平均値を計算(NRは入力ファイルの行数)
awk -F, '{sum += $NF} END{print "Averate:",sum/NR}' score.csv

#保存したawkスクリプト(averate.awk)を再利用する(-fでファイル名を指定)
awk -F, -f average.awk score.csv

# 特定の一より後ろの全てのパラメータを渡す
echo "1,2,3,4,5" | awk -F, '{for (i = 3; i <= NF; i++) print $i;}'
3
4
5

```
