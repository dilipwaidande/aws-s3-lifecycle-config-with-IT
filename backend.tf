# Remote state in S3 with S3-native locking.
# Real values live in backend.hcl (git-ignored), so this repo
# doesn't expose your state bucket name. Initialise with:
#
#   cp backend.hcl.example backend.hcl   # then edit it
#   terraform init -backend-config=backend.hcl

terraform {
  backend "s3" {}
}
