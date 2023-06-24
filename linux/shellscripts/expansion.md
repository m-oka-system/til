## 展開

```bash
# パス名展開で使用できる記号
? 任意の1文字
* 任意の文字列
[] []に含まれる、いずれかの1文字
[! ] []に含まれない、いずれかの1文字
[^ ] [! ]と同じ

# ブレース展開
echo {1..5}
1 2 3 4 5

touch file-{1..3}.txt
file-1.txt file-2.txt file-3.txt

# パラメータ展開
ls $HOME
ls ${HOME}

# デフォルト値を設定
echo ${name:-yamada}
yamada # 未定義の場合は指定の文字を表示
name=taro
echo ${name:-yamada}
taro # 空でない場合は格納されている値を表示

# 変数に値が設定されていない場合のエラー制御
cd $(dir:?You must specify directory)

# パラメータ展開
${変数名#パターン}　 #最短マッチで、パターンに前方一致した部分を取り除く
${変数名##パターン}　#最長マッチで、パターンに前方一致した部分を取り除く
${変数名%パターン}　 #最短マッチで、パターンに後方一致した部分を取り除く
${変数名%%パターン}　#最長マッチで、パターンに後方一致した部分を取り除く

# 置換してから展開
name=yamada
echo $name
yamada
echo ${name/mada/mamoto]
yamamoto

# コマンド置換(コマンドの結果を文字列として取得)
echo $(date +%Y-%m-%d_%H-%M-%S)
echo `date +%Y-%m-%d_%H-%M-%S`

# 算術式展開(2重かっこで括る)
echo $((i + 1))

# プロセス置換
diff < (ls data/miyake) < (ls /data/okita)
```
