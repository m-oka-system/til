# 日本語化の手順

## タイムゾーン

```bash
# 変更前確認
timedatectl
cat /etc/timezone

# タイムゾーン変更
sudo timedatectl set-timezone Asia/Tokyo
```

## ロケール

```bash
# 現在のロケールを確認
localectl
echo $LANG
cat /etc/default/locale

# 使用できるロケールを確認
locale -a

C
C.utf8
POSIX
en_US.utf8

# 日本語ロケールを追加
sudo apt install language-pack-ja -y

# ロケールを変更
sudo update-locale LANG=ja_JP.utf8

echo $LANG
C.utf8 # まだ未反映

# ロケールの反映
source /etc/default/locale
```
