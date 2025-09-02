# IAM Configuration - Phase 0: Terraform State Manager

このディレクトリは、AWS IAM リソースを管理します。現在は Phase 0 として、Terraform State Manager Role のみを実装しています。

## 目的

最小権限の原則に基づき、Terraform 実行用の専用ロールを作成します。これにより：
- S3 ステートバケットへの必要最小限のアクセス
- MFA 必須によるセキュリティ強化
- 管理者権限からの段階的な権限分離

## リソース

### terraform-state-manager ロール
- **用途**: Terraform ステート管理専用
- **権限**: 
  - S3 バケット（natsukium-tfstate）への読み書き
  - 基本的な AWS リソースの読み取り権限
- **セキュリティ**: MFA 必須

## セットアップ

### 1. 初期設定

```bash
cd infra/global/iam

# 初期化
terraform init

# プラン確認
terraform plan
```

### 2. 適用前の準備

variables.tf の `allowed_user_ids` に、ロールを引き受ける IAM ユーザーの ID を設定します：

```hcl
# terraform.tfvars を作成
cat > terraform.tfvars <<EOF
allowed_user_ids = ["AIDAXXXXXXXXXXXXXXXXX"]  # 実際のユーザーIDに置き換え
EOF
```

ユーザー ID の取得方法：
```bash
aws iam get-user --user-name YOUR_USERNAME | jq -r '.User.UserId'
```

### 3. ロールの作成

```bash
terraform apply
```

## 使用方法

### AssumeRole でセッション開始

1. MFA デバイスの ARN を確認：
```bash
aws iam list-mfa-devices --user-name YOUR_USERNAME
```

2. ロールを引き受ける：
```bash
# MFA トークンコードを入力して実行
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/terraform-state-manager \
  --role-session-name terraform-session \
  --serial-number arn:aws:iam::ACCOUNT_ID:mfa/YOUR_MFA_DEVICE \
  --token-code 123456
```

3. 環境変数を設定：
```bash
# assume-role の出力から環境変数を設定
export AWS_ACCESS_KEY_ID=ASIAXXXXXXXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export AWS_SESSION_TOKEN=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

### より簡単な方法（aws-vault 使用）

[aws-vault](https://github.com/99designs/aws-vault) を使用すると、より簡単にロールを引き受けることができます：

```bash
# インストール（macOS）
brew install aws-vault

# プロファイル設定（~/.aws/config）
[profile terraform-state]
role_arn = arn:aws:iam::ACCOUNT_ID:role/terraform-state-manager
mfa_serial = arn:aws:iam::ACCOUNT_ID:mfa/YOUR_MFA_DEVICE
source_profile = default

# 使用
aws-vault exec terraform-state -- terraform plan
aws-vault exec terraform-state -- terraform apply
```

## トラブルシューティング

### "Access Denied" エラー

1. MFA が有効になっていることを確認
2. `allowed_user_ids` に自分のユーザー ID が含まれていることを確認
3. セッショントークンの有効期限を確認（デフォルト: 4時間）

### MFA デバイスが見つからない

```bash
# MFA デバイスの設定
aws iam create-virtual-mfa-device \
  --virtual-mfa-device-name YOUR_MFA_DEVICE \
  --outfile QRCode.png \
  --bootstrap-method QRCodePNG

# Google Authenticator 等でQRコードをスキャン後、有効化
aws iam enable-mfa-device \
  --user-name YOUR_USERNAME \
  --serial-number arn:aws:iam::ACCOUNT_ID:mfa/YOUR_MFA_DEVICE \
  --authentication-code1 123456 \
  --authentication-code2 789012
```

## 次のステップ

Phase 0 完了後、以下の改善を段階的に実施：

1. **Phase 1**: Break Glass User の作成
2. **Phase 2**: 管理者グループとロールベースアクセス
3. **Phase 3**: GitHub Actions OIDC（必要に応じて）
4. **Phase 4**: 最小権限の最適化

## 注意事項

- このロールは S3 ステートバケットへのフルアクセス権限を持ちます
- MFA なしではロールを引き受けることができません
- セッションの有効期限は 4 時間です
- 定期的に権限を見直し、不要な権限を削除してください

## リソース一覧

| リソース | 名前 | 説明 |
|---------|------|------|
| IAM Role | terraform-state-manager | Terraform ステート管理用ロール |
| IAM Policy | terraform-state-access | S3 ステートバケットアクセスポリシー |
| IAM Policy | terraform-minimal-permissions | 基本的な読み取り権限 |