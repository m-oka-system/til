# Authentication（認証）

> 公式: https://terragrunt.gruntwork.io/docs/features/authentication/

## 概要

Terragrunt は AWS 認証と IAM ロール引き受けを処理する複数の方法を提供します。マルチアカウント AWS インフラ管理のセキュリティを担保するための機能です。

## 認証方法

### 1. IAM ロール引き受け（CLI）

3つの設定方法があり、優先順位は CLI引数 > 環境変数 > 設定ファイル です。

**コマンドライン引数**:

```bash
terragrunt apply --iam-assume-role "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
```

**環境変数**:

```bash
export TG_IAM_ASSUME_ROLE="arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
terragrunt apply
```

**設定ファイル** (`terragrunt.hcl`):

```hcl
iam_role = "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
```

### 2. OIDC Web Identity Token

CI/CD パイプラインでロール引き受けと Web ID トークンを組み合わせる方法です。

**コマンドライン**:

```bash
terragrunt apply \
  --iam-assume-role "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME" \
  --iam-assume-role-web-identity-token "$TOKEN"
```

**環境変数**:

```bash
export TG_IAM_ASSUME_ROLE="arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
export TG_IAM_ASSUME_ROLE_WEB_IDENTITY_TOKEN="$TOKEN"
terragrunt apply
```

**設定ファイル**:

```hcl
iam_role             = "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
iam_web_identity_token = get_env("AN_OIDC_TOKEN")
```

### 3. Auth Provider Command（外部スクリプト）

最大限の柔軟性を持つ方法です。

```bash
terragrunt apply --auth-provider-cmd /path/to/auth-script.sh
```

または:

```bash
export TG_AUTH_PROVIDER_CMD="/path/to/auth-script.sh"
terragrunt apply
```

スクリプトは以下のスキーマに準拠した JSON を返す必要があります（全トップレベルオブジェクトはオプション）:

```json
{
  "awsCredentials": {
    "ACCESS_KEY_ID": "string",
    "SECRET_ACCESS_KEY": "string",
    "SESSION_TOKEN": "string (optional)"
  },
  "awsRole": {
    "roleARN": "string (required)",
    "roleSessionName": "string",
    "duration": 3600,
    "webIdentityToken": "string"
  },
  "envs": {
    "ENV_VAR_NAME": "value"
  }
}
```

## 利点

- クレデンシャルがディスクに平文で書き込まれない
- 毎回の実行で新しいクレデンシャルを取得
- Terraform/OpenTofu コードの変更不要
- バックエンド設定の変更不要
- コンテキストごとに異なるロールをサポート（開発者 vs CI/CD）

## マルチアカウント戦略の推奨理由

セキュリティのベストプラクティスとして、インフラを複数の AWS アカウントに分離:

- 開発者がスコープ外のリソースにアクセスすることを防止
- 誤った変更による影響範囲を限定
- 本番環境と開発環境を分離
- IAM Identity Center や OIDC による一時クレデンシャル管理

## S3 ステートバックエンド用の必要最小限の権限

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketVersioning",
        "s3:CreateBucket",
        "s3:PutBucketPolicy"
      ],
      "Resource": "arn:aws:s3:::BUCKET_NAME"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::BUCKET_NAME/some/path/here"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DescribeTable",
        "dynamodb:DeleteItem",
        "dynamodb:CreateTable"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/TABLE_NAME"
    }
  ]
}
```

S3 バケットと DynamoDB テーブルを事前に手動作成し、作成権限ではなく読み書き権限のみを付与することも可能です。
