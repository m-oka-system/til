## ログ

```bash
# すべてのログを表示
journalctl -b

# カーネルのログを表示
journalctl -k

# メッセージカタログも合わせて表示
journalctl -x

# 特定のサービスのログを表示
journalctl -u ssh.service

# 日付の範囲をフィルタ
journalctl -S "2023-06-28 11:00:00" -U "2023-06-28 11:10:00"

# リアルタイムでログを監視する
journalctl -f -u ssh.service

# jsonで出力する
journalctl --output json
```
