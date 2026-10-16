# Incidents and lessons learned

## 1. Lifecycle rule rejected: Glacier too soon after Standard-IA

- **What I did:** set short lab transition days (2 / 4 / 6) to see tiering faster.
- **What happened:** `terraform apply` failed while creating the lifecycle configuration:
  ```text
  InvalidArgument: 'Days' in the 'Transition' action for StorageClass 'GLACIER'
  must be 30 days more than ... the 'Transition' action for StorageClass 'STANDARD_IA'
  ```
  The bucket, KMS key, versioning and Object Lock had already been created, leaving a partial apply.
- **Lesson:** `terraform plan` doesn't catch this. Terraform only checks its own schema; S3 validates transition spacing when the API call is made.

## 2. Lifecycle rule rejected: Deep Archive too soon after Glacier

- **What happened:** after fixing the first gap, the next apply failed:
  ```text
  InvalidArgument: 'Days' in the 'Transition' action for StorageClass 'DEEP_ARCHIVE'
  must be 90 days more than ... the 'Transition' action for StorageClass 'GLACIER'
  ```
- **Fix:** 19 / 60 / 160 days, which applied successfully.
- **Lesson:** S3 enforces a gap after each class that matches that class's minimum storage duration (30 days for Standard-IA, 90 for Glacier). AWS reports one validation error at a time, so each error revealed one rule.

## 3. Object Lock blocks deletes, as intended

- **What I did:** uploaded a file to `logs/` and tried to delete its version.
- **What happened:** `AccessDenied: Access Denied because object protected by object lock.` The same delete with `--bypass-governance-retention` succeeded.
- **Lesson:** governance mode protects against accidental and unauthorised deletes, while still letting an admin with `s3:BypassGovernanceRetention` clean up. Compliance mode would have made the object undeletable for the full retention period, which is why the lab uses governance.

## 4. Destroy needs an empty bucket

- **Lesson:** S3 won't delete a bucket that still holds object versions or delete markers. Under Object Lock, each version must be deleted with the governance bypass before `terraform destroy` can remove the bucket. See the clean-up steps in the README.
