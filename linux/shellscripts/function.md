## シェル関数

```bash
# 関数定義
function <関数名> ()
{
	処理
}

# ()を省略
function <関数名>
{
	処理
}

# functionを省略
<関数名> ()
{
	処理
}

# 終了ステータスを指定
<関数名> ()
{
	処理
	return 1
}
```

## スクリプト基本構文

- パーミッションは「755：rwxr-xr-x」

```bash
#!/usr/bin/env bash

# スクリプト実行環境を定義
set -euo pipefail

# このスクリプト自身が置かれているディレクトリに移動する
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# エントリポイント
function main() {
  # なにか処理を呼び出す

	# 実行スクリプトのパスを取得して他のスクリプトを読み込み
	local cwd
	cwd="$(cd "$(dirname "$0")" && pwd)"
	. $cwd/import.sh
}

# このスクリプトファイルが直接実行された場合のみmain関数を実行する
# 他のスクリプトファイルからsourceで呼ばれた場合は実行しない
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# setオプション
e エラーが発生するとスクリプトを停止する
u 未定義の変数が使用されているとスクリプトを停止する
o pipefail パイプ処理の中のいずれかの処理が失敗するとスクリプトを停止する

以下と同じ意味
set -o errexit
set -o nounset
set -o pipefail
```
