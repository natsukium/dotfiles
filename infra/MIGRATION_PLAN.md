# Terraform Infrastructure Migration Plan

## 現状分析

### 現在の構成の問題点
1. **混在したプロバイダー管理**: OCI、AWS、Hydra、Cloudflare、GitHubが単一ファイルに混在
2. **不明瞭なステート管理**: 分散しているが構造が体系化されていない
3. **モジュール化の不足**: 再利用可能なコンポーネントが少ない
4. **環境分離の欠如**: 本番環境のみで開発/ステージング環境がない
5. **変数管理の分散**: 一元管理されていない設定値

## 新構成案

### ディレクトリ構造

```
infra/
├── environments/           # 環境別設定
│   └── production/        # 本番環境
│       ├── main.tf       # メインエントリポイント
│       ├── variables.tf  # 変数定義
│       ├── terraform.tfvars # 環境固有の値
│       ├── outputs.tf    # 出力定義
│       ├── versions.tf   # プロバイダーバージョン管理
│       └── backend.tf    # バックエンド設定
│
├── modules/               # 再利用可能なモジュール
│   ├── compute/          # コンピューティングリソース
│   │   ├── oci-instance/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   └── nixos-anywhere/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   │
│   ├── networking/       # ネットワーキング
│   │   ├── oci-network/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── cloudflare-dns/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   │
│   ├── ci-cd/           # CI/CD
│   │   └── hydra/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   │
│   ├── iam/             # アイデンティティ管理
│   │   └── github-oidc/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   │
│   └── storage/         # ストレージ
│       └── terraform-backend/
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
│
├── global/              # グローバルリソース（1度だけ作成）
│   ├── terraform-backend/
│   │   ├── main.tf
│   │   └── backend.tf
│   └── dns-zones/
│       ├── main.tf
│       └── backend.tf
│
├── scripts/             # ヘルパースクリプト
│   ├── decrypt-ssh-secret.sh
│   └── terraform-wrapper.sh
│
├── .github/            # GitHub Actions
│   └── workflows/
│       ├── terraform-plan.yml
│       └── terraform-apply.yml
│
├── Makefile            # タスク自動化
├── .pre-commit-config.yaml # pre-commit設定
├── .terraform-version  # tfenvバージョン管理
└── README.md          # ドキュメント
```

## 移行計画

### Phase 1: 基盤整備（1週目）

#### 1.1 グローバルリソースの設定
- S3バックエンドの再構成
- DynamoDBステートロックテーブルの追加
- 基本的なIAMロールの設定

#### 1.2 開発環境の整備
- pre-commitフックの設定
- terraform-docsの導入
- tflint/tfsecの設定

### Phase 2: モジュール化（2週目）

#### 2.1 OCIモジュール
```hcl
# modules/compute/oci-instance/main.tf
resource "oci_core_instance" "this" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  shape               = var.shape
  
  shape_config {
    memory_in_gbs = var.memory_in_gbs
    ocpus         = var.ocpus
  }
  
  # ... 詳細設定
}
```

#### 2.2 Cloudflareモジュール
```hcl
# modules/networking/cloudflare-dns/main.tf
resource "cloudflare_dns_record" "records" {
  for_each = var.dns_records
  
  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.content
  proxied = each.value.proxied
  ttl     = each.value.ttl
}
```

### Phase 3: 環境統合（3週目）

#### 3.1 Production環境の設定
```hcl
# environments/production/main.tf
module "oci_network" {
  source = "../../modules/networking/oci-network"
  
  compartment_id = local.compartment_id
  vcn_cidr       = var.vcn_cidr
  subnet_cidr    = var.subnet_cidr
}

module "nix_builder" {
  source = "../../modules/compute/oci-instance"
  
  instance_name       = "serengeti"
  compartment_id      = local.compartment_id
  subnet_id          = module.oci_network.subnet_id
  ssh_authorized_keys = var.ssh_authorized_keys
}

module "cloudflare_dns" {
  source = "../../modules/networking/cloudflare-dns"
  
  zone_id     = var.cloudflare_zone_id
  dns_records = local.dns_records
}
```

### Phase 4: 移行実行（4週目）

#### 4.1 リソースのインポート
```bash
# 既存リソースを新しい構成にインポート
terraform import module.nix_builder.oci_core_instance.this ocid1.instance.oc1...
terraform import module.cloudflare_dns.cloudflare_dns_record.records["blog"] d318cc678ba046e46f9a7bc69f735764/xxx
```

#### 4.2 ステート移行
```bash
# ステートの移行
terraform state mv oci_core_instance.nix-builder module.nix_builder.oci_core_instance.this
```

## ベストプラクティスの適用

### 1. 命名規則
- リソース名: `{provider}_{resource_type}_{logical_name}`
- モジュール名: `{category}-{specific_function}`
- 変数名: `snake_case`

### 2. タグ戦略
```hcl
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "natsukium"
    Project     = "home-infrastructure"
  }
}
```

### 3. セキュリティ
- SOPSでの暗号化を継続
- GitHub OIDCを使用したAWS認証
- 最小権限の原則

### 4. バージョン管理
```hcl
# versions.tf
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}
```

## 自動化

### Makefile
```makefile
.PHONY: init plan apply destroy fmt validate docs

init:
	terraform init -upgrade

plan: fmt validate
	terraform plan -out=tfplan

apply:
	terraform apply tfplan

destroy:
	terraform destroy -auto-approve

fmt:
	terraform fmt -recursive

validate:
	terraform validate

docs:
	terraform-docs markdown modules/ > docs/MODULES.md

lint:
	tflint --recursive
	tfsec .
```

### Pre-commit hooks
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
      - id: terraform_tflint
      - id: terraform_tfsec
```

## 監視とログ

### 1. CloudWatch/OCI Monitoringの活用
- インフラストラクチャメトリクスの収集
- アラート設定

### 2. コスト管理
- AWS Cost Explorerの設定
- OCI Cost Analysisの活用
- 月次レポートの自動生成

## リスクと対策

### リスク
1. **ダウンタイム**: 移行中のサービス停止
2. **設定ミス**: 新構成での設定誤り
3. **ステート破損**: 移行中のステート不整合

### 対策
1. **Blue-Green deployment**: 新旧環境を並行運用
2. **徹底したテスト**: plan実行とレビュー
3. **バックアップ**: ステートファイルの定期バックアップ

## 成功指標

- [ ] すべてのリソースがモジュール化される
- [ ] CI/CDパイプラインが稼働
- [ ] ドキュメントが最新化される
- [ ] 変更のロールバックが15分以内に可能
- [ ] インフラ変更が自動テストされる

## タイムライン

| 週 | タスク | 完了基準 |
|---|--------|----------|
| 1 | 基盤整備 | バックエンド設定完了、開発環境構築 |
| 2 | モジュール作成 | 全モジュールのテスト完了 |
| 3 | 環境統合 | production環境の設定完了 |
| 4 | 移行実行 | 全リソースの移行完了、動作確認 |

## 次のステップ

1. このプランのレビューと承認
2. バックアップの作成
3. Phase 1の開始