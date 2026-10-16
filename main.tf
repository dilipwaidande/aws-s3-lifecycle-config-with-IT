# Terraform Configuration: Automated S3 Cost Optimization, Lifecycle & WORM Vault

# 1. Random Suffix for Unique Bucket Naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 2. S3 Bucket with Object Lock Enabled
resource "aws_s3_bucket" "compliance_vault" {
  bucket              = "${var.bucket_prefix}-${random_string.suffix.result}"
  object_lock_enabled = true

  tags = {
    Environment = "Lab"
    Purpose     = "WORM-Compliance-Log-Vault"
    Project     = "S3-Cost-Optimization"
  }
}

# 3. Block All Public Access (Security Best Practice)
resource "aws_s3_bucket_public_access_block" "vault_security" {
  bucket                  = aws_s3_bucket.compliance_vault.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 4. Customer Managed Key (CMK) for KMS Encryption
resource "aws_kms_key" "vault_key" {
  description             = "Customer Managed Key (CMK) for S3 Compliance Vault Encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "vault_key_alias" {
  name          = "alias/s3-compliance-vault-key"
  target_key_id = aws_kms_key.vault_key.key_id
}

# 5. Server-Side Encryption Configuration with SSE-KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "vault_encryption" {
  bucket = aws_s3_bucket.compliance_vault.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.vault_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}
# 6. S3 Bucket Versioning (Required for Object Lock)
resource "aws_s3_bucket_versioning" "vault_versioning" {
  bucket = aws_s3_bucket.compliance_vault.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 7. Default S3 Object Lock Configuration (Compliance Mode)
resource "aws_s3_bucket_object_lock_configuration" "vault_object_lock" {
  bucket = aws_s3_bucket.compliance_vault.id

  rule {
    default_retention {
      mode = "GOVERNANCE" # use COMPLIANCE to prevent delete via root account

      days = 7 # use 365 in Production
    }
  }

  depends_on = [aws_s3_bucket_versioning.vault_versioning]
}

# 8. S3 Lifecycle Configuration (Cost Optimization Tiering)
resource "aws_s3_bucket_lifecycle_configuration" "vault_lifecycle" {
  bucket = aws_s3_bucket.compliance_vault.id

  # Rule 1: Automated Tiering for Logs & Archives
  rule {
    id     = "auto-tiering-and-archival-rule"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    transition {

      days          = 19 
      storage_class = "STANDARD_IA"
    }

    transition {

      days          = 60 # 30+ days minimum required against the value of STANDARD_IA
      storage_class = "GLACIER"
    }

    transition {

      days          = 160 # 90+ days minimum required against the value GLACIER
      storage_class = "DEEP_ARCHIVE"
    }

    noncurrent_version_expiration {

      noncurrent_days = 7 # noncurrent_days = 365
    }
  }

  # Rule 2: Intelligent-Tiering for Unpredictable Access Patterns
  rule {
    id     = "unpredictable-data-intelligent-tiering"
    status = "Enabled"

    filter {
      prefix = "unpredictable/"
    }

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

# 9. Requester Pays Configuration (Shift Egress / Retrieval Costs)
resource "aws_s3_bucket_request_payment_configuration" "vault_requester_pays" {
  count  = var.enable_request_pays ? 1 : 0
  bucket = aws_s3_bucket.compliance_vault.id
  payer  = "Requester"
}