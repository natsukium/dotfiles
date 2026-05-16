resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "${data.aws_caller_identity.current.account_id}-cloudtrail-logs"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket                  = aws_s3_bucket.cloudtrail_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Audit logs may be needed retroactively, so no expiration. Transition to
# Glacier after 90 days for cost — at-rest access is still possible, just
# slower.
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    id     = "archive-to-glacier"
    status = "Enabled"

    filter {}

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# Bucket policy following the AWS-documented format for organization
# trails: log paths are namespaced under the org ID rather than per
# account ID, so the allow rule must reference the org ID.
data "aws_iam_policy_document" "cloudtrail_logs_bucket" {
  statement {
    sid = "CloudTrailAclCheck"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_logs.arn]
  }

  statement {
    sid = "CloudTrailWrite"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    # Org trails write under the org-id-namespaced path, but CloudTrail's
    # preflight CreateTrail check additionally validates writes at the
    # management account's account-id path; both must be allowed.
    resources = [
      "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
      "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.terraform_remote_state.organization.outputs.organization_id}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_logs_bucket.json
}

# Service-linked role for CloudTrail. Enabling cloudtrail.amazonaws.com
# as a trusted service in Organizations does not auto-provision the SLR;
# without it, CreateTrail with is_organization_trail=true fails with
# InsufficientDependencyServiceAccessPermissionException.
resource "aws_iam_service_linked_role" "cloudtrail" {
  aws_service_name = "cloudtrail.amazonaws.com"
}

# Organization trail captures API activity from every member account
# (including future ones) into a single bucket in the management account.
# is_multi_region_trail ensures regional services are also covered without
# needing one trail per region.
resource "aws_cloudtrail" "org_trail" {
  name           = "org-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.id

  is_organization_trail         = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_logs,
    aws_iam_service_linked_role.cloudtrail,
  ]
}

output "cloudtrail_logs_bucket" {
  value = aws_s3_bucket.cloudtrail_logs.id
}

output "org_trail_arn" {
  value = aws_cloudtrail.org_trail.arn
}
