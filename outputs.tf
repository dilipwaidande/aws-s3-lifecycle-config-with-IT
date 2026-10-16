output "s3_bucket_name" {
  value       = aws_s3_bucket.compliance_vault.id
  description = "Name of the created S3 Compliance Vault Bucket"
}

output "kms_key_arn" {
  value       = aws_kms_key.vault_key.arn
  description = "ARN of the Customer Managed Key (CMK) used for SSE-KMS encryption"
}

output "object_lock_status" {
  value       = "GOVERNANCE (7 Days Retention)"
  description = "Status of S3 Object Lock"
}