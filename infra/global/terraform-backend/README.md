# Terraform Backend Configuration

このモジュールは、Terraform ステート管理用の S3 バックエンドインフラストラクチャを管理します。

## 機能

- S3 バケットによるステートファイル管理
- S3 ネイティブステートロック（Terraform 1.10+ の `use_lockfile` 機能を使用）
- バージョニングによるステート履歴管理
- 暗号化によるセキュリティ強化
- パブリックアクセスブロック
- 古いバージョンの自動削除（90日後）
- オプショナルなアクセスログ

## S3 ネイティブステートロック

Terraform 1.10 以降では、DynamoDB を使用せずに S3 だけでステートロックが可能になりました。

### 仕組み

- ステートファイルと同じ場所に `.tflock` 拡張子のロックファイルが作成されます
- `If-None-Match` ヘッダーを使用して、ファイルが存在しない場合のみ書き込みを許可
- 同時に一つのプロセスだけがステートファイルを更新できることを保証

### 利点

- DynamoDB テーブルが不要（コスト削減）
- 必要な IAM 権限の削減
- インフラストラクチャの簡素化

## 使用方法

### 初期セットアップ

1. 最初の実行時は、ローカルバックエンドで実行します：
```bash
terraform init
terraform apply
```

2. S3 バケットが作成されたら、バックエンドをS3に移行します：
```bash
terraform init -migrate-state
```

### 他のプロジェクトでの使用

他の Terraform プロジェクトで、このバックエンドを使用するには：

```hcl
terraform {
  backend "s3" {
    bucket       = "natsukium-tfstate"
    key          = "path/to/your/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true  # S3 native locking
  }
}
```

## 必要な権限

最小限必要な IAM 権限：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "arn:aws:s3:::natsukium-tfstate",
        "arn:aws:s3:::natsukium-tfstate/*"
      ]
    }
  ]
}
```

## 入力変数

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `aws_region` | AWS region for the S3 bucket | `string` | `"us-east-2"` | no |
| `state_bucket_name` | Name of the S3 bucket for Terraform state | `string` | `"natsukium-tfstate"` | no |
| `enable_logging` | Enable S3 access logging for the state bucket | `bool` | `false` | no |
| `environment` | Environment name | `string` | `"global"` | no |
| `project` | Project name | `string` | `"home-infrastructure"` | no |

## 出力値

| Name | Description |
|------|-------------|
| `state_bucket_name` | Name of the S3 bucket for Terraform state |
| `state_bucket_arn` | ARN of the S3 bucket for Terraform state |
| `state_bucket_region` | Region of the S3 bucket |

## 注意事項

- このモジュールは既存のバケット `natsukium-tfstate` を管理下に置きます
- `prevent_destroy` ライフサイクルルールにより、誤削除を防いでいます
- 古いバージョンは90日後に自動削除されます