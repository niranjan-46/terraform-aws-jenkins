# ==============================================================================
# Module: Backup (DLM Lifecycle Policy)
# Purpose: Creates daily EBS snapshots with 7-day retention for data protection
# Commit: feat(backup): Configure daily EBS snapshots with DLM lifecycle policy
# ==============================================================================

# ------------------------------------------------------------------------------
# DLM Lifecycle Policy
# Automated daily snapshots of Jenkins data EBS volume
# - Frequency: Daily (24 hours)
# - Retention: 30 days (INCREASED for better data protection)
# - Target: Jenkins data EBS volume
# Commit: feat(backup): Create DLM policy for daily snapshots with extended retention
# ------------------------------------------------------------------------------
resource "aws_dlm_lifecycle_policy" "daily_snapshots" {
  name        = "${var.project_name}-${var.environment}-daily-backup"
  description = "Daily EBS snapshots for Jenkins data volume with 30-day retention"

  state = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedules {
      name           = "DailyBackup"
      frequency      = "24hours"
      retention_days = 30  # INCREASED: Better retention for production workloads
      copy_tags      = true

      tags_to_add {
        BackupType = "DailySnapshot"
        Retention  = "30Days"
      }
    }
  }

  target {
    resource_types = ["VOLUME"]

    volumes {
      volume_ids = [var.volume_id]
    }
  }
}