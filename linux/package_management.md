## yum

```bash
# パッケージのインストール
yum install -y <パッケージ名>

# インストールパッケージの確認
yum list installed | grep <パッケージ名>

# パッケージの削除(erase/removeどちらも同じ)
yum erase -y <パッケージ名>
yum remove -y <パッケージ名>

# パッケージの検索
yum search <検索キーワード>

# パッケージの説明文まで含めた全文検索
yum search all <検索キーワード>

# パッケージ情報の表示
yum info <パッケージ名>

# 除外
yum update --exclude=kernel*,redhat-release*

# CVE指定
yum update --cve CVE-XXXX-XXXX

# conf
/etc/yum.conf
exclude=kernel* redhat-release*
yum update

# アップデート可能なパッケージの一覧を表示
yum check-update
```

## apt

```bash
# パッケージのインストール(インストール確認のプロンプトは表示されない)
apt-get install <パッケージ名>

# パッケージの削除
apt-get remove -y <パッケージ名>

# 設定ファイルも含めたパッケージの完全削除
apt-get purge <パッケージ名>

# パッケージの検索(パッケージの説明文まで含める)
apt-cache search <検索キーワード>

# パッケージ名だけで検索
apt-cache search --names-only <検索キーワード>

# パッケージ情報の表示
apt-cache show <パッケージ名>

# パッケージの検索と情報表示を同時に行う
apt-cache search --full <パッケージ名>
```
