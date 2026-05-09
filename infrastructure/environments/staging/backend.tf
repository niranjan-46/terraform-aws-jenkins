terraform {
  backend "s3" {
    bucket         = "jenkins-staging-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "jenkins-staging-state-lock"
  }
}