| ツール名 | 説明                                                                                                                                              |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| go       | プログラミング言語。kind を `go install` で入れる際に必要。WSL 上で事前にセットアップする。                                                       |
| docker   | コンテナ実行基盤。kind は Docker 上に Kubernetes クラスタを構築するため、WSL 内に Docker を入れておく必要がある。                                 |
| kubectl  | Kubernetes クラスタに対して操作・確認を行うための公式コマンドライン。クラスタの状態把握やデプロイのために必須。                                   |
| kind     | Kubernetes in Docker の略。Docker コンテナ上に Kubernetes クラスタを構築するツール。軽量で開発・CI 用途に向く。minikube の代替として WSL で使う。 |

## go

```bash
# インストール
wget https://go.dev/dl/go1.25.6.linux-amd64.tar.gz
tar zxvf go1.25.6.linux-amd64.tar.gz
sudo mv go /usr/local/
rm -rf go1.25.6.linux-amd64.tar.gz

# PATH を .bashrc に追加
cat << "EOF" >> ~/.bashrc

# go lang
export PATH=$PATH:/usr/local/go/bin

EOF

# バージョン確認（要: 新しいターミナルまたは source ~/.bashrc）
go version
```

## docker

```bash
# 前提パッケージのインストール
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release -y

# Docker 公式リポジトリの追加
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
 "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
 $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker のインストール
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

# ユーザーを docker グループに追加（要: 再ログインまたは newgrp docker）
cat /etc/group | grep docker
sudo usermod -aG docker $USER

# 動作確認
docker --version
docker ps
```

## kubectl

```bash
# インストール（安定版をダウンロード）
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256) kubectl" | sha256sum --check

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# バージョン確認
kubectl version
```

## kind

```bash
# go と同じ PATH にインストール（go install を利用）
GOPATH=/usr/local/go/ go install sigs.k8s.io/kind@v0.31.0

# パス・バージョン確認（要: /usr/local/go/bin が PATH に含まれていること）
which kind
kind --version

# クラスタ作成と確認
kind create cluster
kubectl get nodes
```

## 参考 URL

- https://techblog.ap-com.co.jp/entry/2024/04/23/120021
- https://go.dev/dl/
- https://matsuand.github.io/docs.docker.jp.onthefly/engine/install/ubuntu/
- https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
- https://kind.sigs.k8s.io/docs/user/quick-start
