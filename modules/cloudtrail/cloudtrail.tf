# ───────────────────────────────────────────────────────────────
# DATA SOURCES: Metadata about current AWS account & environment
# ───────────────────────────────────────────────────────────────
data "aws_caller_identity" "current" {} # Gets AWS account ID
data "aws_partition" "current" {}       # Gets partition (usually "aws", might be "aws-cn" or "aws-us-gov")
data "aws_region" "current" {}          # Gets current AWS region

# ───────────────────────────────────────────────────────────────
# STEP 1: Create an S3 bucket to store CloudTrail logs
# Note: Bucket name must be globally unique across all AWS accounts
# ───────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "cloudtrail_logs_bucket" {
  bucket = "onedata-cloudtrail-logs-09-07-2025" # Change to a unique name if needed
}

# ───────────────────────────────────────────────────────────────
# STEP 2: Block public access to the bucket (Security best practice)
# ───────────────────────────────────────────────────────────────
resource "aws_s3_bucket_public_access_block" "cloudtrail_logs_bucket_pab" {
  bucket = aws_s3_bucket.cloudtrail_logs_bucket.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ───────────────────────────────────────────────────────────────
# STEP 3: Enable versioning on the S3 bucket
# Recommended so old log files aren't lost on overwrite
# ───────────────────────────────────────────────────────────────
resource "aws_s3_bucket_versioning" "cloudtrail_logs_bucket_versioning" {
  bucket = aws_s3_bucket.cloudtrail_logs_bucket.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

# ───────────────────────────────────────────────────────────────
# STEP 4: Enable server-side encryption (SSE) using AES256
# Ensures CloudTrail logs are encrypted at rest
# ───────────────────────────────────────────────────────────────
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs_bucket_encryption" {
  bucket = aws_s3_bucket.cloudtrail_logs_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ───────────────────────────────────────────────────────────────
# STEP 5: Create a bucket policy that allows CloudTrail to:
# - Read bucket ACL (GetBucketAcl)
# - Write logs to the bucket (PutObject)
# Requires a specific SourceArn (CloudTrail) and ACL condition
# ───────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "s3_bucket_policy_statements" {
  # Allow CloudTrail to GetBucketAcl for validation
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_logs_bucket.arn]

    # Ensures this permission is only used by our CloudTrail trail
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${aws_cloudtrail.cloudtrail_logs.name}"]
    }
  }

  # Allow CloudTrail to PutObject with proper ACL
  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail_logs_bucket.arn}/cloudtrail-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    # Ensures CloudTrail writes objects with proper ownership
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    # Scope to only this trail via SourceArn
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${aws_cloudtrail.cloudtrail_logs.name}"]
    }
  }
}

# ───────────────────────────────────────────────────────────────
# STEP 6: Attach the above policy to the S3 bucket
# Depends on public access block being applied before
# ───────────────────────────────────────────────────────────────
resource "aws_s3_bucket_policy" "attached_policy_with_s3" {
  bucket = aws_s3_bucket.cloudtrail_logs_bucket.id
  policy = data.aws_iam_policy_document.s3_bucket_policy_statements.json

  depends_on = [aws_s3_bucket_public_access_block.cloudtrail_logs_bucket_pab]
}

# ───────────────────────────────────────────────────────────────
# STEP 7: Create the CloudTrail trail
# - Sends logs to the above S3 bucket
# - Covers all regions (multi-region)
# - Logs all management + S3/Lambda data events
# ───────────────────────────────────────────────────────────────
resource "aws_cloudtrail" "cloudtrail_logs" {
  depends_on = [aws_s3_bucket_policy.attached_policy_with_s3]

  name           = "org-cloudtrail-${data.aws_region.current.name}"  # Must be unique per region
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs_bucket.bucket
  s3_key_prefix  = "cloudtrail-logs"  # Appears as folder in bucket

  include_global_service_events = true    # Capture IAM-level events
  is_multi_region_trail         = true    # Enables logging from all regions
  enable_log_file_validation    = true    # Adds SHA256 hashes for integrity

  # Fine-grained data logging (optional, but good for compliance/audit)
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::*/*"] # Monitor all object-level activity
    }

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda:*:*:function:*"] # Monitor all Lambda functions
    }
  }

  tags = {
    Name        = "Organization CloudTrail"
    Environment = "production"
    Purpose     = "audit-logging"
  }
}

# ───────────────────────────────────────────────────────────────
# OUTPUTS: Reference values after apply
# ───────────────────────────────────────────────────────────────
output "cloudtrail_bucket_name" {
  description = "Name of the S3 bucket storing CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_logs_bucket.bucket
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.cloudtrail_logs.arn
}

output "cloudtrail_home_region" {
  description = "Home region of the CloudTrail trail"
  value       = aws_cloudtrail.cloudtrail_logs.home_region
}
