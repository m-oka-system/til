# Ubuntu

```bash
# Azure VM
sudo snap install docker
sudo addgroup docker
sudo adduser azureuser docker
sudo reboot
```

# Amazon Linux

```bash
# docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# amazon-linux-extrasを利用したインストール
sudo amazon-linux-extras install docker

# docker compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

# Linter / Formatter

## Linter (hadlint)

1. GitHub から hadolint-Windows-x86_64.exe をダウンロード
1. hadolint.exe にリネームして PATH の通っている場所に配置（または、PATH を追加）
1. VSCode の拡張機能「hadolint」をインストール

## Formater

1. VSCode の拡張機能「Docker」をインストール
1. settings.json に以下を追記して保存時のフォーマットを有効化

```json
    "[dockerfile]": {
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "ms-azuretools.vscode-docker"
    }
```
