terraform {
  backend "s3" {
    bucket         = "jenkins-prod-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "jenkins-prod-state-lock"
  }
}