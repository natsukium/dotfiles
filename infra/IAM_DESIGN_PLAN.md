# AWS IAM設計計画

## 現状分析

### 現在の課題
- ルートアカウントの使用
- 管理者権限を持つIAMユーザー（宣言的管理なし）
- Terraformによる管理が行われていない
- 権限が広すぎる（何でもできるアカウント）
- MFAの設定が不明確

## 提案するIAM構成

### アカウント階層構造
```
Root Account (緊急時のみ、MFA必須)
├── Break Glass User (緊急時用、MFA必須)
├── IAM Groups
│   ├── admins (管理者グループ)
│   └── developers (将来の開発者用)
├── IAM Roles
│   ├── terraform-admin (Terraform実行用)
│   ├── terraform-state-manager (State管理専用)
│   ├── readonly (読み取り専用)
│   └── github-actions-* (CI/CD用、将来)
└── Service Accounts
    └── github-actions (OIDC、将来)
```

## 実装フェーズ

### Phase 0: 即時対応（優先度: 高）
**Terraform Stateアクセスの確保**
```hcl
# terraform-state-manager ロール
- S3 バケット (natsukium-tfstate) への読み書き権限
- 既存の管理者ユーザーから AssumeRole 可能
- Terraform 実行時はこのロールを使用
```

**理由**: 
- 現在のTerraform操作の継続性を確保
- 最小権限の原則の第一歩
- 他の変更を安全に行うための基盤

### Phase 1: 基礎設定（Week 1）
1. **Break Glass User作成**
   - ルートアカウントの代替
   - ハードウェアMFAまたは仮想MFA設定
   - 普段は無効化

2. **パスワードポリシー設定**
   - 最小14文字
   - 複雑性要件
   - 90日でローテーション

3. **Terraform State Manager Role作成**
   - S3バケットアクセス権限
   - 既存ユーザーからのAssumeRole許可

### Phase 2: ロール移行（Week 2）
1. **管理者グループとロール**
   ```hcl
   # admins グループ
   - AssumeRole権限のみ付与
   - MFA必須ポリシー適用
   
   # terraform-admin ロール
   - 管理者グループからAssumeRole可能
   - 初期はAdministratorAccess（後で絞る）
   ```

2. **既存ユーザーの移行**
   - 直接権限からロールベースへ
   - セッション時間の設定（1-4時間）

### Phase 3: GitHub Actions OIDC（Week 3、オプション）
1. **OIDC Provider設定**
   ```hcl
   aws_iam_openid_connect_provider {
     url = "https://token.actions.githubusercontent.com"
     client_id_list = ["sts.amazonaws.com"]
   }
   ```

2. **CI/CD用ロール作成**
   - terraform-plan用（読み取りのみ）
   - terraform-apply用（制限付き書き込み）

### Phase 4: 最小権限化（Week 4）
1. **権限の段階的削減**
   - CloudTrailログ分析
   - 実際に使用している権限の特定
   - 不要な権限の削除

2. **Permissions Boundary設定**
   - 権限の上限設定
   - 危険な操作の防止

## IAMリソース設計詳細

### ユーザー設計
```hcl
# Break Glass User
aws_iam_user "break_glass" {
  name = "break-glass-emergency"
  tags = {
    Purpose = "Emergency access only"
    MFA     = "Required"
  }
}

# 既存管理者ユーザー（移行後）
aws_iam_user "natsukium_admin" {
  name = "natsukium-admin"
  tags = {
    Owner = "natsukium"
    Type  = "Human"
  }
}
```

### グループ設計
```hcl
# 管理者グループ
aws_iam_group "admins" {
  name = "admins"
  path = "/humans/"
}

aws_iam_group_membership "admin_members" {
  name  = "admin-membership"
  group = aws_iam_group.admins.name
  users = [aws_iam_user.natsukium_admin.name]
}

# グループポリシー（AssumeRoleのみ）
aws_iam_group_policy_attachment "admin_assume_role" {
  group      = aws_iam_group.admins.name
  policy_arn = aws_iam_policy.assume_admin_role.arn
}
```

### ロール設計
```hcl
# Terraform State管理ロール（最優先）
aws_iam_role "terraform_state_manager" {
  name = "terraform-state-manager"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/natsukium-admin"
      }
      Action = "sts:AssumeRole"
      Condition = {
        Bool = {
          "aws:MultiFactorAuthPresent" = "true"
        }
      }
    }]
  })
}

# Terraform管理者ロール
aws_iam_role "terraform_admin" {
  name = "terraform-admin"
  max_session_duration = 14400  # 4時間
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_group.admins.arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      }
    ]
  })
}
```

### ポリシー設計
```hcl
# Terraform State アクセスポリシー（最優先）
aws_iam_policy "terraform_state_access" {
  name        = "terraform-state-access"
  description = "Access to Terraform state in S3"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::natsukium-tfstate",
          "arn:aws:s3:::natsukium-tfstate/*"
        ]
      }
    ]
  })
}

# MFA強制ポリシー
aws_iam_policy "enforce_mfa" {
  name        = "enforce-mfa"
  description = "Enforce MFA for all actions except initial MFA setup"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowViewAccountInfo"
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "iam:ListVirtualMFADevices"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowManageOwnVirtualMFADevice"
        Effect = "Allow"
        Action = [
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice"
        ]
        Resource = "arn:aws:iam::*:mfa/$${aws:username}"
      },
      {
        Sid    = "AllowManageOwnUserMFA"
        Effect = "Allow"
        Action = [
          "iam:DeactivateMFADevice",
          "iam:EnableMFADevice",
          "iam:ListMFADevices",
          "iam:ResyncMFADevice"
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      },
      {
        Sid    = "DenyAllExceptListedIfNoMFA"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice",
          "sts:GetSessionToken"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
}
```

### セキュリティ設定
```hcl
# パスワードポリシー
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_letters      = true
  require_numbers                = true
  require_uppercase_letters      = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age                = 90
  password_reuse_prevention       = 5
}
```

## 監査とコンプライアンス

### CloudTrail設定
```hcl
aws_cloudtrail "main" {
  name           = "main-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.id
  
  event_selector {
    read_write_type           = "All"
    include_management_events = true
    
    data_resource {
      type   = "AWS::IAM::Role"
      values = ["arn:aws:iam::*"]
    }
  }
}
```

### Access Analyzer
```hcl
aws_accessanalyzer_analyzer "main" {
  analyzer_name = "main-analyzer"
  type          = "ACCOUNT"
}
```

## ディレクトリ構造
```
infra/
└── global/
    └── iam/
        ├── main.tf           # プロバイダー設定
        ├── users.tf          # ユーザー定義
        ├── groups.tf         # グループ定義
        ├── roles.tf          # ロール定義
        ├── policies.tf       # カスタムポリシー
        ├── attachments.tf    # ポリシーアタッチメント
        ├── oidc.tf          # OIDC設定（将来）
        ├── security.tf       # セキュリティ設定
        ├── variables.tf      # 変数定義
        ├── outputs.tf        # 出力値
        ├── backend.tf        # バックエンド設定
        └── README.md         # ドキュメント
```

## 移行手順

### 1. 事前準備
- [ ] 現在の権限をバックアップ（AWS CLI出力）
- [ ] ルートアカウントのMFA設定確認
- [ ] 緊急時の連絡先確認

### 2. Terraform State Manager Role作成（最優先）
```bash
# 1. ロールとポリシーを作成
terraform apply -target=aws_iam_role.terraform_state_manager
terraform apply -target=aws_iam_policy.terraform_state_access

# 2. ロールにポリシーをアタッチ
terraform apply -target=aws_iam_role_policy_attachment.terraform_state_manager

# 3. AssumeRoleのテスト
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT:role/terraform-state-manager \
  --role-session-name terraform-session
```

### 3. 段階的な権限移行
- Week 1: Break Glass User作成、基本設定
- Week 2: ロールベースアクセスへ移行
- Week 3: CI/CD設定（オプション）
- Week 4: 権限の最適化

## リスクと対策

### リスク
1. **ロックアウト**: 権限設定ミスでアクセス不能
2. **作業中断**: 権限不足でTerraform実行不可
3. **MFA紛失**: デバイス故障でログイン不可

### 対策
1. **Break Glass User**: 緊急時アクセス確保
2. **段階的移行**: 一度に全部変更しない
3. **バックアップMFA**: 複数のMFAデバイス登録
4. **ロールバック手順**: 各ステップで戻し方を文書化

## 成功指標

### 短期（1ヶ月）
- [ ] Terraform State Manager Role経由でのTerraform実行
- [ ] すべてのIAMユーザーでMFA有効化
- [ ] Break Glass User作成と文書化

### 中期（3ヶ月）
- [ ] ルートアカウント使用ゼロ
- [ ] すべてのアクセスがロール経由
- [ ] CloudTrailによる監査ログ記録

### 長期（6ヶ月）
- [ ] 最小権限の原則完全適用
- [ ] 定期的な権限レビュープロセス確立
- [ ] インシデント対応手順の確立

## 次のステップ

1. **即時実行**: Terraform State Manager Roleの作成
   - S3バケットアクセス権限の確保
   - 現在の作業継続性の保証

2. **Week 1**: 基礎設定の実装
   - Break Glass User
   - パスワードポリシー
   - MFA設定

3. **継続的改善**: 
   - CloudTrailログ分析
   - 使用されていない権限の削除
   - セキュリティベストプラクティスの適用