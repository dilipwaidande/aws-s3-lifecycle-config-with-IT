variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region for deployment"
}

variable "bucket_prefix" {
  type        = string
  default     = "compliance-vault-logs"
  description = "Prefix for the S3 compliance vault bucket"
}

variable "enable_request_pays" {
  type        = bool
  default     = false
  description = "Enable Requester Pays for cross-account auditor access"
}