# cert-manager インストール方法の比較調査

> 調査日: 2026-02-23
> 対象バージョン: cert-manager v1.17.1（Microsoft ドキュメント） / v1.19.2（cert-manager 公式）

## 調査目的

AKS クラスター上に cert-manager をインストールする際の 2 つの手順を比較し、適切な方法を特定します。

- Microsoft ドキュメント: Application Gateway + Let's Encrypt チュートリアル
- cert-manager 公式ドキュメント: AKS + Let's Encrypt チュートリアル

## 結論

**cert-manager 公式ドキュメントの方法を採用します。**

理由は以下の通りです。

- OCI レジストリが公式の「source of truth」であり、リリース直後に利用可能になる
- `crds.enabled` が現行の推奨オプションである（`installCRDs` は非推奨）
- 1 コマンドで完結し、手順のミスが起きにくい
- 不要な手順（disable-validation ラベル等）が含まれていない

## 予備知識: CRD（Custom Resource Definition）とは

CRD は Kubernetes 標準の API 拡張機能です（v1.7 で導入）。Kubernetes の組み込みリソース（`Pod`, `Service` 等）に加え、独自のリソース型を追加できます。

cert-manager をインストールすると、以下の CRD が登録されます。

| CRD                  | 用途                               |
| -------------------- | ---------------------------------- |
| `Certificate`        | 発行する証明書の定義               |
| `CertificateRequest` | 証明書発行リクエスト               |
| `Issuer`             | 証明書発行者（名前空間スコープ）   |
| `ClusterIssuer`      | 証明書発行者（クラスタースコープ） |
| `Order`              | ACME プロトコルの注文管理          |
| `Challenge`          | ACME チャレンジの管理              |

CRD は「リソース型の定義（スキーマ）」であり、実際の処理は Controller（cert-manager 本体）が担当します。CRD が登録されていないと Kubernetes は `Certificate` や `ClusterIssuer` を認識できないため、cert-manager 本体より先に、または同時にインストールする必要があります。

## インストールコマンドの比較

### Microsoft ドキュメントの手順（6 ステップ）

```bash
# 1. CRD を手動適用
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.1/cert-manager.crds.yaml

# 2. 名前空間を手動作成
kubectl create namespace cert-manager

# 3. disable-validation ラベルを付与（現在は不要）
kubectl label namespace cert-manager cert-manager.io/disable-validation=true

# 4. レガシー Helm リポジトリを追加
helm repo add jetstack https://charts.jetstack.io

# 5. リポジトリを更新
helm repo update

# 6. Helm チャートをインストール
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.17.1
```

### cert-manager 公式ドキュメントの手順（1 コマンド）

```bash
helm install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.19.2 \
  --set crds.enabled=true
```

## 比較表

| 項目                      | Microsoft ドキュメント                               | cert-manager 公式ドキュメント                                |
| ------------------------- | ---------------------------------------------------- | ------------------------------------------------------------ |
| チャートソース            | `jetstack/cert-manager`（レガシー HTTP repo）        | `oci://quay.io/jetstack/charts/cert-manager`（OCI registry） |
| バージョン                | v1.17.1                                              | v1.19.2                                                      |
| CRD インストール          | `kubectl apply` で別途適用 + `installCRDs`（非推奨） | `--set crds.enabled=true`（現行推奨）                        |
| 名前空間作成              | 手動で `kubectl create namespace`                    | `--create-namespace` フラグで自動作成                        |
| disable-validation ラベル | あり（不要になった古い手順）                         | なし                                                         |
| 手順のステップ数          | 6 ステップ                                           | 1 コマンド                                                   |

## 問題点の詳細（Microsoft ドキュメント側）

### 1. レガシー Helm リポジトリの使用

`helm repo add jetstack https://charts.jetstack.io` は旧方式です。cert-manager 公式によると、OCI Helm チャートが「source of truth」であり、レガシーリポジトリは OCI 公開後に数時間遅れて更新されます。

### 2. `installCRDs` は非推奨

cert-manager v1.15 以降、`installCRDs` は `crds.enabled` + `crds.keep` に置き換えられました。Microsoft ドキュメントのコメントにある `--set installCRDs=true` は非推奨オプションです。

### 3. CRD の二重管理リスク

Microsoft の手順では以下の 2 つの方法で CRD を管理しています。

1. `kubectl apply -f cert-manager.crds.yaml` で CRD を手動適用
2. Helm チャートでも CRD をインストール可能（`installCRDs=true`）

管理主体が不明確になり、アップグレード時に不整合が生じるリスクがあります。

### 4. `disable-validation` ラベルは不要

```bash
kubectl label namespace cert-manager cert-manager.io/disable-validation=true
```

このラベルは cert-manager v0.x 時代に Webhook の検証を回避するために必要でした。現在のバージョンでは不要です。

### 5. バージョンの乖離

v1.17.1 は最新の v1.19.2 と比較して 2 マイナーバージョン遅れています。セキュリティ修正やバグ修正が含まれていない可能性があります。

## 推奨インストールコマンド

```bash
helm install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.19.2 \
  --set crds.enabled=true
```

このコマンドで以下がすべて完了します。

- `cert-manager` 名前空間の作成
- CRD のインストール
- cert-manager のデプロイ（controller, webhook, cainjector）

## インストール後の確認コマンド

```bash
# Pod の状態を確認
kubectl get pods -n cert-manager

# CRD の確認
kubectl get crds | grep cert-manager

# cert-manager のバージョンを確認
helm list -n cert-manager
```

## 参考リンク

- [cert-manager 公式 Helm インストール手順](https://cert-manager.io/docs/installation/helm/)
- [cert-manager AKS チュートリアル](https://cert-manager.io/docs/tutorials/getting-started-aks-letsencrypt/)
- [Microsoft ドキュメント - Application Gateway で Let's Encrypt 証明書を使用する](https://learn.microsoft.com/ja-jp/azure/application-gateway/ingress-controller-letsencrypt-certificate-application-gateway)
- [cert-manager Release Notes 1.15（CRD オプション変更）](https://cert-manager.io/docs/releases/release-notes/release-notes-1.15/)
- [cert-manager CRD Issue #7096](https://github.com/cert-manager/cert-manager/issues/7096)
