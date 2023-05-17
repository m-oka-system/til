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
1. GitHubからhadolint-Windows-x86_64.exeをダウンロード
1. hadolint.exeにリネームしてPATHの通っている場所に配置（または、PATHを追加）
1. VSCodeの拡張機能「hadolint」をインストール

## Formater
1. VSCodeの拡張機能「Docker」をインストール
1. settings.jsonに以下を追記して保存時のフォーマットを有効化
```json
    "[dockerfile]": {
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "ms-azuretools.vscode-docker"
    }
```
