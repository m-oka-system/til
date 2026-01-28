## Helm コマンド

### Helm 固有の用語集

| 用語           | 説明                                                                                                                                                                                  |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Chart**      | Kubernetes アプリケーションをパッケージ化したもの。アプリケーションのデプロイに必要なすべてのリソース定義（Deployment、Service など）を含むテンプレートとデフォルト設定値で構成される |
| **Release**    | Chart をインストールした結果として作成されるインスタンス。同じ Chart から複数の Release を作成でき、それぞれに固有の名前が付けられる                                                  |
| **Repository** | Chart を保存・共有するための場所。HTTP サーバーや OCI レジストリなどでホストされる。Helm はリポジトリから Chart をダウンロードして使用する                                            |
| **Values**     | Chart のテンプレートに渡す設定値。デフォルト値は `values.yaml` に定義され、`--set` オプションや `-f` オプションで上書きできる                                                         |
| **Template**   | Chart 内の Kubernetes マニフェストファイル。Go テンプレート構文を使用して、Values の値に基づいて動的にリソース定義を生成する                                                          |
| **Manifest**   | Template が Values と結合されて生成された、実際の Kubernetes リソース定義（YAML 形式）。`helm install` 実行時に Kubernetes クラスターに適用される                                     |
| **Hook**       | Release のライフサイクルの特定の時点（インストール前、アップグレード後など）で実行される Job や Pod。データベースのマイグレーションなどに使用される                                   |
| **Dependency** | Chart が他の Chart に依存している場合の関係。`Chart.yaml` の `dependencies` セクションで定義され、`helm dependency update` でダウンロードされる                                       |
| **Revision**   | Release の各バージョンに付けられる番号。`helm upgrade` を実行するたびに新しい Revision が作成され、`helm rollback` で以前の Revision に戻せる                                         |

### 基本構文

```bash
helm install    # チャートをインストール
helm upgrade    # リリースをアップグレード
helm uninstall  # リリースをアンインストール
helm list       # リリース一覧を表示
helm status     # リリースの状態を確認
helm get        # リリースの情報を取得
helm repo       # リポジトリを管理
helm search     # チャートを検索
helm template   # チャートをテンプレート化
helm lint       # チャートを検証
helm package    # チャートをパッケージ化
```

### リポジトリ管理

```bash
helm repo add <repo_name> <repo_url>  # リポジトリを追加
helm repo list                        # リポジトリ一覧を表示
helm repo update                      # リポジトリを更新
helm repo remove <repo_name>          # リポジトリを削除
helm repo index <directory>           # リポジトリインデックスを生成
```

### チャートの検索

```bash
helm search repo <keyword>             # リポジトリからチャートを検索
helm search repo <keyword> --versions  # バージョン情報を含めて検索
helm search hub <keyword>              # Helm Hub からチャートを検索
helm search all <keyword>              # すべてのソースから検索
```

### チャートのインストール

```bash
helm install <release_name> <chart>             　　　# チャートをインストール
helm install <release_name> <chart> -n <namespace>   # 名前空間を指定してインストール
helm install <release_name> <chart> --set key=value  # 値を設定してインストール
helm install <release_name> <chart> -f values.yaml   # values.yaml ファイルを使用
helm install <release_name> <chart> --dry-run        # ドライラン（実際にはインストールしない）
helm install <release_name> <chart> --debug          # デバッグモードで実行
```

### リリースの管理

```bash
helm list                                       # すべてのリリースを表示
helm list -n <namespace>                        # 特定の名前空間のリリースを表示
helm list --all                                 # 削除されたリリースも含めて表示
helm list --all-namespaces                      # すべての名前空間のリリースを表示
helm status <release_name>                      # リリースの状態を確認
helm status <release_name> -n <namespace>       # 名前空間を指定して状態を確認
helm uninstall <release_name>                   # リリースをアンインストール
helm uninstall <release_name> -n <namespace>    # 名前空間を指定してアンインストール
helm uninstall <release_name> --keep-history    # 履歴を保持したままアンインストール
```

### リリースのアップグレード

```bash
helm upgrade <release_name> <chart>                     # リリースをアップグレード
helm upgrade <release_name> <chart> --set key=value     # 値を設定してアップグレード
helm upgrade <release_name> <chart> -f values.yaml      # values.yaml ファイルを使用
helm upgrade <release_name> <chart> --install           # 存在しない場合はインストール
helm upgrade <release_name> <chart> --dry-run           # ドライラン
helm upgrade <release_name> <chart> --reuse-values      # 既存の値を再利用
helm rollback <release_name> <revision>                 # リリースをロールバック
helm rollback <release_name> <revision> -n <namespace>  # 名前空間を指定してロールバック
helm history <release_name>                             # リリースの履歴を表示
```

### リリース情報の取得

```bash
helm get manifest <release_name>            # マニフェストを取得
helm get values <release_name>              # 設定値を取得
helm get notes <release_name>               # リリースノートを取得
helm get hooks <release_name>               # フックを取得
helm get all <release_name>                 # すべての情報を取得
helm get all <release_name> -n <namespace>  # 名前空間を指定して取得
```

### チャートの開発

```bash
helm create <chart_name>                              # 新しいチャートを作成
helm lint <chart_path>                                # チャートを検証
helm lint <chart_path> --strict                       # 厳格モードで検証
helm package <chart_path>                             # チャートをパッケージ化
helm template <release_name> <chart>                  # チャートをテンプレート化して表示
helm template <release_name> <chart> --set key=value  # 値を設定してテンプレート化
helm template <release_name> <chart> -f values.yaml   # values.yaml を使用してテンプレート化
helm dependency list <chart_path>                     # 依存関係を一覧表示
helm dependency update <chart_path>                   # 依存関係を更新
helm dependency build <chart_path>                    # 依存関係をビルド
```

### よく使うオプション

```bash
-n, --namespace <namespace>  # 名前空間を指定
--set <key>=<value>          # 値を設定（複数指定可能）
-f, --values <file>          # values.yaml ファイルを指定
--dry-run                    # ドライラン（実際には実行しない）
--debug                      # デバッグモードで実行
--wait                       # リソースが準備完了するまで待機
--timeout <duration>         # タイムアウトを設定（例: 5m）
--atomic                     # 失敗時にロールバック
--create-namespace           # 名前空間が存在しない場合は作成
```

## Helm と Kustomize の比較

| 比較軸       | Helm                                     | Kustomize                                         |
| :----------- | :--------------------------------------- | :------------------------------------------------ |
| **管理方式** | テンプレート+values.yamlで値を差し込む   | YAMLをベースにして差分をパッチ適用              |
| **主な用途** | OSSチャートのインストール                | 内製マニフェストの差分管理                        |
| **環境切替** | `-f dev.yaml` で切替                     | `overlays/dev` などでディレクトリ単位で切替       |
| **拡張性**   | ループや条件分岐など、柔軟なテンプレートが可能 | YAMLをそのまま記述するため可読性とシンプルさに強み |
