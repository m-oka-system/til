## URL

https://cert-manager.io/docs/tutorials/getting-started-aks-letsencrypt/

## 前提条件

- AKS クラスターが作成されていること (OIDC Issuer が有効化されている)
- Azure DNS ゾーンが作成されていること (委任済み)
- マネージド ID が作成されていること
- マネージド ID に DNS Zone Contributor のロールが付与されていること
- マネージド ID にフェデレーション資格情報が作成されていること

## 手順

```bash
# cert-manager インストール
helm install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.19.2 \
  --set crds.enabled=true \
  --values values.yaml

# cert-manager アップグレード (必要な場合)
existing_cert_manager_version=$(helm get metadata -n cert-manager cert-manager | grep '^VERSION' | awk '{ print $2 }')
helm upgrade cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --reuse-values \
  --namespace cert-manager \
  --version $existing_cert_manager_version \
  --values values.yaml

# インストール確認
kubectl -n cert-manager get all

# ClusterIssuer 作成 (以下の変数を環境に合わせて設定)
export AZURE_DEFAULTS_GROUP=<your-resource-group-name>
export IDENTITY_NAME=<your-certmanager-identity-name>
export DOMAIN_NAME=<your-domain.com>
export EMAIL_ADDRESS=<your-email@example.com>
export AZURE_SUBSCRIPTION=$(az account show --query 'name' -o tsv)
export AZURE_SUBSCRIPTION_ID=$(az account show --name $AZURE_SUBSCRIPTION --query 'id' -o tsv)
export USER_ASSIGNED_IDENTITY_CLIENT_ID=$(az identity show --name $IDENTITY_NAME --resource-group $AZURE_DEFAULTS_GROUP --query 'clientId' -o tsv)
envsubst < clusterissuer-lets-encrypt-staging.yaml | kubectl apply -f  -

# ClusterIssuer 確認
kubectl describe clusterissuer letsencrypt-staging

```

```bash
# cert-manager アンインストール
helm uninstall cert-manager -n cert-manager

# cert-manager 名前空間削除
kubectl delete namespace cert-manager
```
