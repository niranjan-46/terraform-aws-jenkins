output "bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}

output "bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table" {
  value = aws_dynamodb_table.terraform_locks.name
}