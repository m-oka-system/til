## kubectl コマンド

### 基本構文

```bash
kubectl get       #　一覧表示
kubectl describe  # 詳細表示
kubectl create    # リソースを作成
kubectl delete    # リソースを削除
kubectl apply     # マニフェストを適用
kubectl logs      # Pod のログを確認
kubectl exec      # Pod 内でコマンドを実行
```

### コンテキスト関連

```bash
kubectl config current-context                                      # 現在のコンテキストを表示
kubectl config get-contexts                                         # コンテキスト一覧を表示
kubectl config use-context <context_name>                           # コンテキストを切り替え
kubectl config set-context <context_name> --namespace <name_space>  # 名前空間を指定
kubectl config delete-context <context_name>                        # コンテキストを削除
```

### マニフェストを適用

```bash
kubectl apply -f pod.yml
kubectl apply -f ./dir #ディレクトリ配下のすべてのymlが対象
kubectl apply -f ./dir　-R
```

### リソースを取得

```bash
# すべてのリソース種別を表示
kubectl api-resources

# 特定の Pod を表示
kubectl get <resource>
kubectl get pods -o wide                        # ワイド表示
kubectl get pods -o yml sample-pod              # sample-podの情報をyamlで表示
kubectl get pods -o jsonpath="{.metadata.name}" # 特定の値を取得する場合によく利用する
kubectl get pods -o jsonpath="{.spec.containers[?(@.name == 'nginx-container')].image}" #条件でフィルタ

-l                    ラベルでフィルタリング
--show-labels         付与されているラベルを表示
-o                    指定した形式(json/yamlなど)で出力
-w                    リアルタイムでウォッチする
--output-watch-events APIイベントを出力する
```

### Pod のコンテナに接続

```bash
kubectl exec -it sample-pod -c <container_name> -- bash
```

### ポートフォワーディング

```bash
kubectl port-forward sample-pod 8080:80
kubectl port-forward sample-pod 8080:80 >> /dev/null 2>&1 &
```

### Pod のログを出力

```bash
kubectl logs sample-pod # Pod のログをダンプします(標準出力)
kubectl logs -l name=myLabel # name=myLabel ラベルの持つ Pod のログをダンプします(標準出力)
kubectl logs my-pod --previous # 以前に存在したコンテナの Pod ログをダンプします(標準出力)
kubectl logs my-pod -c my-container # 複数コンテナがある Pod で、特定のコンテナのログをダンプします(標準出力)
kubectl logs -f my-pod # Pod のログをストリームで確認します(標準出力)
kubectl logs -f my-pod -c my-container # 複数のコンテナがある Pod で、特定のコンテナのログをストリームで確認します(標準出力)
kubectl logs -f -l name=myLabel --all-containers # name-myLabel ラベルを持つすべてのコンテナのログをストリームで確認します(標準出力)
```

### ファイルコピー

```bash
kubectl cp sample-pod:etc/hostname ./hostname # コンテナからローカルにファイルをコピー
kubectl cp hostname sample-pod:/tmp/newfile # ローカルからコンテナにファイルをコピー
```

### Pod を直接起動

```bash
kubectl run --image=mysql5.7 --restart=Never mysql-client --command -- tail -f /dev/null
kubectl run curl-box --image=curlimages/curl --restart=Never --command -- sleep infinity
```
