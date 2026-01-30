## URL

https://learn.microsoft.com/ja-jp/azure/aks/csi-secrets-store-identity-access

## 前提条件

- CSI Driver アドオンの有効化
- マネージド ID に Key Vault Secrets User ロールの割り当て
- Key Vault とシークレットの作成

## 手順

```bash
# SecretProviderClass の作成
# userAssignedIdentityID, keyvaultName, tenantId, objectName, objectType を書き換えること
kubectl apply -f secretproviderclass.yaml
kubectl get secretproviderclass

# Pod の作成
kubectl apply -f pod.yaml
kubectl get pod

# 動作確認
kubectl describe pod busybox-secrets-store-inline-user-msi
kubectl exec busybox-secrets-store-inline-user-msi -- ls /mnt/secrets-store/
kubectl exec busybox-secrets-store-inline-user-msi -- cat /mnt/secrets-store/ExampleSecret
kubectl exec -it busybox-secrets-store-inline-user-msi -- sh

# Kubernetes リソースの削除
kubectl delete -f secretproviderclass.yaml
kubectl delete -f pod.yaml
```
