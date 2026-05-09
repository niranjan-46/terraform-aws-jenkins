# ==============================================================================
# Module: State (S3 + DynamoDB)
# Purpose: Creates S3 bucket for Terraform state storage and DynamoDB for locking
# Commit: feat(state): Provision S3 bucket and DynamoDB for Terraform state management
# ==============================================================================

# ------------------------------------------------------------------------------
# S3 Bucket: Terraform State Storage
# Remote state storage with versioning and encryption enabled
# Commit: feat(state): Create S3 bucket for remote Terraform state
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket = "jenkins-${var.environment}-terraform-state"

  tags = merge(var.tags, {
    Name        = "jenkins-${var.environment}-terraform-state"
    Environment = var.environment
  })
}

# ------------------------------------------------------------------------------
# S3 Bucket Versioning
# Enables versioning for state file history and recovery
# Commit: feat(state): Enable versioning on S3 state bucket
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------------------------------------------------------------
# S3 Bucket Server-Side Encryption
# Encrypts state files at rest using AES-256
# Commit: feat(state): Enable server-side encryption on S3 bucket
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ------------------------------------------------------------------------------
# S3 Bucket Public Access Block
# Prevents accidental public access to state files
# Commit: feat(state): Block public access to S3 state bucket
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# DynamoDB Table: State Locking
# Prevents concurrent state modifications during apply operations
# Commit: feat(state): Create DynamoDB table for Terraform state locking
# ------------------------------------------------------------------------------
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "jenkins-${var.environment}-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(var.tags, {
    Name        = "jenkins-${var.environment}-state-lock"
    Environment = var.environment
  })
}