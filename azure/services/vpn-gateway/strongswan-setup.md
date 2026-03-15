# strongSwan S2S VPN セットアップ手順

Azure VPN Gateway と Ubuntu VM 間で S2S VPN 接続を確立する手順。

## 前提条件

- Ubuntu VM（24.04 LTS で検証済み）
- VM にパブリック IP が付与されていること
- Azure 側に以下が構築済みであること:
  - VPN Gateway（`VpnGw1AZ` 以上）
  - Local Network Gateway（VM のパブリック IP と対向側アドレス空間を設定）
  - VPN Connection（IPsec、PSK 設定済み）

## 必要な情報

| 項目                      | 説明                                        | 例                     |
| ------------------------- | ------------------------------------------- | ---------------------- |
| VM パブリック IP          | strongSwan 側のグローバル IP                | `203.0.113.10`         |
| VM サブネット             | 対向側として広告するアドレス空間            | `10.0.0.0/16`          |
| VPN Gateway パブリック IP | Azure 側のゲートウェイ IP                   | `198.51.100.1`         |
| Azure VNet アドレス空間   | VPN 経由でアクセスする Azure 側ネットワーク | `172.16.0.0/16`        |
| PSK（事前共有キー）       | 両端で一致させる共有キー                    | `YourPreSharedKey123!` |

## 手順

### 1. strongSwan インストール

```bash
sudo apt-get update
sudo apt-get install -y strongswan
```

> dpkg エラーが出た場合は `sudo dpkg --configure -a` を先に実行する。

### 2. IPsec 設定ファイル作成

`/etc/ipsec.conf` を以下の内容で作成する。

```bash
sudo tee /etc/ipsec.conf > /dev/null << 'EOF'
config setup
    charondebug="ike 2, knl 2, cfg 2"

conn azure-vpn
    keyexchange=ikev2
    authby=secret
    left=%defaultroute
    leftid=<VM パブリック IP>
    leftsubnet=<VM サブネット CIDR>
    right=<VPN Gateway パブリック IP>
    rightsubnet=<Azure VNet CIDR>
    ike=aes256-sha384-ecp384,aes256-sha256-ecp256,aes256-sha256-modp2048,aes256-sha256-modp1024,aes256-sha1-modp1024
    esp=aes256gcm16,aes256-sha256,aes256-sha1
    keyingtries=%forever
    ikelifetime=28800s
    lifetime=27000s
    dpddelay=10s
    dpdtimeout=30s
    dpdaction=restart
    auto=start
    type=tunnel
EOF
```

#### パラメータ説明

| パラメータ           | 説明                                                          |
| -------------------- | ------------------------------------------------------------- |
| `keyexchange=ikev2`  | IKEv2 プロトコルを使用                                        |
| `left=%defaultroute` | ローカル側 IP を自動検出（NAT 環境対応）                      |
| `leftid`             | ローカル側の識別子（パブリック IP を指定）                    |
| `leftsubnet`         | ローカル側が広告するネットワーク範囲                          |
| `right`              | Azure VPN Gateway のパブリック IP                             |
| `rightsubnet`        | Azure 側のネットワーク範囲                                    |
| `ike`                | IKE Phase 1 の暗号スイート（複数提示し Azure 側に選択させる） |
| `esp`                | ESP（Phase 2）の暗号スイート                                  |
| `dpdaction=restart`  | Dead Peer Detection でピアが応答しない場合に自動再接続        |
| `auto=start`         | サービス起動時に自動接続                                      |

### 3. PSK（事前共有キー）設定

`/etc/ipsec.secrets` に PSK を設定する。

```bash
sudo tee /etc/ipsec.secrets > /dev/null << EOF
<VM パブリック IP> <VPN Gateway パブリック IP> : PSK "<PSK>"
EOF
sudo chmod 600 /etc/ipsec.secrets
```

### 4. strongSwan 起動

```bash
sudo ipsec restart
```

`auto=start` により自動で接続を開始する。

### 5. 接続確認

```bash
# ステータス確認（ESTABLISHED であれば成功）
sudo ipsec status

# 詳細確認（IKE/ESP プロポーザル、トラフィック量など）
sudo ipsec statusall
```

期待する出力:

```
Security Associations (1 up, 0 connecting):
   azure-vpn[1]: ESTABLISHED xx seconds ago, 10.0.1.4[203.0.113.10]...198.51.100.1[198.51.100.1]
   azure-vpn{1}:  INSTALLED, TUNNEL, reqid 1, ESP in UDP SPIs: xxxxxxxx_i xxxxxxxx_o
   azure-vpn{1}:   10.0.0.0/16 === 172.16.0.0/16
```

### 6. Azure 側の接続確認

```bash
az network vpn-connection show \
  --resource-group <リソースグループ名> \
  --name <VPN 接続名> \
  --query '{status:connectionStatus, protocol:connectionProtocol}' \
  -o json
```

`"status": "Connected"` であれば Azure 側も正常。

## トラブルシューティング

### NO_PROPOSAL_CHOSEN エラー

暗号スイートが Azure 側と合っていない。`ike` と `esp` に複数のプロポーザルを指定して Azure 側に選択させる。`!` サフィックス（厳密指定）は使わない。

### ESTABLISHED だが Azure 側が NotConnected

Azure 側のステータス反映に数分かかる場合がある。しばらく待って再確認する。

### 手動で接続を開始

```bash
sudo ipsec up azure-vpn
```

### ログ確認

```bash
sudo journalctl -u strongswan-starter -f
```

## 停止・削除

```bash
# 接続を停止
sudo ipsec down azure-vpn

# サービスを停止
sudo ipsec stop

# アンインストール
sudo apt-get remove -y strongswan
```
