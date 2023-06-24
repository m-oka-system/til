## タイムゾーン

```bash
# 変更前確認
timedatectl
               Local time: 日 2021-03-21 07:19:46 UTC
           Universal time: 日 2021-03-21 07:19:46 UTC
                 RTC time: 日 2021-03-21 07:19:45
                Time zone: Etc/UTC (UTC, +0000)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no

# タイムゾーン変更
# タイムゾーンを一時的に変更したい場合は、環境変数TZでタイムゾーンを設定
sudo timedatectl set-timezone Asia/Tokyo

# 変更後確認
timedatectl
               Local time: 日 2021-03-21 16:21:30 JST
           Universal time: 日 2021-03-21 07:21:30 UTC
                 RTC time: 日 2021-03-21 07:21:29
                Time zone: Asia/Tokyo (JST, +0900)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no
```

## ロケール

```bash
# 変更前確認
cat locale.conf
LANG=en_US.UTF-8

echo $LANG
en_US.UTF-8   # 一時的に言語を変更する場合は環境変数LANGを変更すればよい

locale
LANG=en_US.UTF-8
LC_CTYPE="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_COLLATE="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_PAPER="en_US.UTF-8"
LC_NAME="en_US.UTF-8"
LC_ADDRESS="en_US.UTF-8"
LC_TELEPHONE="en_US.UTF-8"
LC_MEASUREMENT="en_US.UTF-8"
LC_IDENTIFICATION="en_US.UTF-8"
LC_ALL=

# RHEL8など日本語のロケールが存在しない場合はインストール
yum search locale ja
glibc-langpack-ja.x86_64 : Locale data for ja

# ロケールインストール
sudo yum install glibc-langpack-ja

locale -a | grep ja
ja_JP.eucjp
ja_JP.utf8

# ロケールを変更
sudo localectl set-locale LANG=ja_JP.utf8

# ロケールの反映
source /etc/locale.conf
```

## キーボード設定

```bash

# 変更前確認
localectl
System Locale: LANG=ja_JP.utf8
      VC Keymap: us
      X11 Layout: us

cat cat /etc/vconsole.conf
System Locale: LANG=ja_JP.utf8
       VC Keymap: us
      X11 Layout: us

# 使用できるキーマップを表示
localectl list-keymaps | grep jp
jp
jp-OADG109A
jp-dvorak
jp-kana86
jp106

# 日本語キーボードに設定
sudo localectl set-keymap jp106
or
sudo localectl set-keymap jp
sudo localectl set-x11-keymap jp

```
