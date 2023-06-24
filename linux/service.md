## サービス

```bash
# サービス登録
/etc/systemd/ssytem/<unit_file>

# systemdに読み込み
systemctl daemon-reload

# サービス一覧表示
systemctl list-unit-files

# サービス状態確認
systemctl status <unit_name>

# サービス開始/終了
systemctl start <unit_name>
systemctl stop <unit_name>

# サービス自動起動の有効化/無効化
systemctl enable <unit_name>
systemctl disable <unit_name>

# サービス自動起動の確認
systemctl is-enabled <unit_name>
```
