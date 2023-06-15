# Ubuntu

以下のいずれかの Source リストにリポジトリを追加

- `/etc/apt/sources.list`
- `/etc/apt/sources.list.d/nginx.list`

```bash
# リリース名を確認
cat /etc/lsb-release
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=20.04
DISTRIB_CODENAME=focal
DISTRIB_DESCRIPTION="Ubuntu 20.04.6 LTS"

# Ubunt 20.04 (focal)
sudo vi /etc/apt/sources.list.d/nginx.list

deb https://nginx.org/packages/ubuntu/ focal nginx
deb-src https://nginx.org/packages/ubuntu/ focal nginx

sudo apt update
sudo apt install nginx

# GPGエラーが表示された場合は以下を実行 (キーはエラーメッセージのものに置き換え)
# GPG error: https://nginx.org/packages/ubuntu focal InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY ABF5BD827BD9BF62

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
sudo apt update
sudo apt install nginx
sudo systemctl start nginx
# sudo service nginx start

# インストールされたパッケージの確認
apt show nginx

# nginxパッケージに含まれるファイルとディレクトリの一覧を表示
dpkg -L nginx
```
