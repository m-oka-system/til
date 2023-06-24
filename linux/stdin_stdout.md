## 標準入出力

```bash
# 標準入出力の数値
0:標準入力
1:標準出力
2:標準エラー出力

# 入力リダイレクトとファイル指定
cat < /etc/crontab #入力リダイレクトでの書き方
cat /etc/crontab #ファイル指定での書き方

# 出力リダイレクト
command > result.log

# コマンドをグループ化してリダイレクト ()で囲んでもOK。()の場合はサブシェルで実行
{
	date +%Y-%m-%d
	echo '/usr list'
	ls /user
} > result.txt


# 標準出力、標準エラー出力の両方をファイルにリダイレクト
command > result.log 2>&1

# 標準出力、標準エラー出力を別々のファイルにリダイレクト
command > info.log 2> error.log

# 標準出力を捨てる
command > /dev/null

# 標準出力、標準エラー出力の両方を捨てる
command > /dev/null 2>&1　※シェルチェック推奨
command &> /dev/null

# 標準エラー出力のみを表示
command 2>&1 1>/dev/null
command 2> error.log

# リダイレクトによるファイル上書きの防止
set -o noclobber

# ファイル上書き防止を無視して強制的に上書き
command >| error.log

# 標準エラーもパイプラインに送る
ls -l /xxxx 2>&1 | less
```

## ヒアドキュメント

```bash
# 書き方
コマンド << END(終了文字列)
ヒアドキュメントの内容
END(終了文字列)

# パラメータ展開、コマンド置換、算術式展開も可能
script_name=ls
cat << END
Usage: $script_name [OPTION]...[FILE]
List information about this Files
END

# エスケープ
# \でエスケープ
cat << END
Usage: \$script_name [OPTION]...[FILE]
END

# <<の右に書く終了文字をクォートで囲む
cat << 'END'
Usage: $script_name [OPTION]...[FILE]
END

# 行頭のタブを無視する
cat <<- END

# 変数に代入する
CMD=$(cat << EOF
ls
EOF
)
```

## フィルタ

```bash
# ファイルの先頭の10行を表示
head /etc/crontab

コマンド履歴を10行だけ表示
history | head

# その他の代表的なフィルタ
tail:末尾の部分を表示
grep:指定した検索パターンに一致する行だけを表示
sort:順番に並び替え(数値で並び替えする場合は、-n オプションを指定、降順にする場合は -r を指定)
uniq:重複した行を取り除く
tac:逆順に出力
wc:行数やバイト数を出力

# ファイルサイズの大きい上位5つを表示
du -b /bin/* | sort -n | tac | head -n 5
```

## tee コマンド (標準出力とファイルに書き出す)

```bash
# ファイルを上書きする
<command> | tee result.txt

# ファイルに追記する
<command> | tee -a result.txt
```

## ログ出力

```bash
LOGFILE="/var/log/initialize.log"
exec > "${LOGFILE}"  # 以降の標準出力を全て ファイル に出力
exec 2>&1            # 標準出力、標準エラー出力の両方をファイルにリダイレクト
```
