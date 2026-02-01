| ツール名  | 説明                                                                                                                                              |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| OrbStack  | 高速・軽量な仮想化レイヤーで Docker コンテナや Linux マシンをシンプルに動かせる macOS 向けツール。Docker Desktop 代替として素早く試す目的に使う。 |
| kubectl   | Kubernetes クラスタに対して操作・確認を行うための公式コマンドライン。クラスタの状態把握やデプロイのために必須。                                   |
| minikube  | ローカルにシングルノードの Kubernetes クラスタを作るツール。開発・学習用にクラスタを手軽に再現する目的で使う。                                    |
| kustomize | Kubernetes のマニフェストを管理するためのツール。マニフェストの差分を管理する目的で使う。                                                         |
| helm      | Kubernetes 用のパッケージマネージャー。複雑なマニフェストをテンプレート化し、再利用性とバージョン管理を高めるために使う。                         |
| kubectx   | kubectl の context や namespace をコマンド一発で切り替える補助ツール。入力ミスによる誤操作を防ぎ、操作対象を素早く変えるために使う。              |
| stern     | 複数 Pod のログを同時に追跡し、色分けで見やすくするログビューア。リアルタイムでの障害調査やデバッグをシンプルにするために使う。                   |
| kubecolor | kubectl の出力を色分けして見やすくするツール。kubectl の出力をより読みやすくするために使う。                                                      |
| kube-ps1  | 現在のコンテキストと名前空間をプロンプトに表示するツール。                                                                                        |

## OrbStack

```bash
# インストール
brew install orbstack
orb version
```

## kubectl

```bash
# インストール
brew install kubectl
kubectl version --client
```

## minikube

```bash
# インストール
brew install minikube
minikube version

# minikube 起動
minikube start

# minikube 状態確認
kubectl get nodes
kubectl cluster-info
minikube status

# Dashboard を起動
minikube dashboard

# Docker イメージを読み込む
minikube image load <image_name:tag>

# minikube に SSH 接続する
minikube ssh
minikube ssh -- docker images
```

## kustomize

```bash
# インストール
brew install kustomize
kustomize version
```

## helm

```bash
# インストール
brew install helm
```

## kubectx

```bash
# インストール
brew install kubectx

# Context 一覧を表示
kubectx

# Context を切り替え
kubectx <context_name>

# Namespace 一覧を表示
kubens

# Namespace を切り替え
kubens <namespace_name>
```

## stern

```bash
# インストール
brew install stern
stern --version
```

## kubecolor

```bash
# インストール
brew install hidetatz/tap/kubecolor
kubecolor version
```

## kube-ps1

```bash
# インストール
brew install kube-ps1
```

## Alias

```bash
# kubernetes
alias k='kubecolor'
alias ka='kubectl apply'
alias kd='kubectl delete'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdc='kubectl describe configmap'
alias kdi='kubectl describe ingress'
alias kpf='kubectl port-forward'
alias kcg='kubectl config get-contexts'
alias kc='kubectx | peco | xargs kubectx'
alias kn='kubens | peco | xargs kubens'
alias st='stern'

# get zsh complete kubectl
source <(kubectl completion zsh)
alias kubectl=kubecolor

# make completion work with kubecolor
compdef kubecolor=kubectl

# kube-ps1
source "/opt/homebrew/opt/kube-ps1/share/kube-ps1.sh"
PROMPT='$(kube_ps1)'$PROMPT
```
