terraform {
  backend "s3" {
    bucket         = "jenkins-dev-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "jenkins-dev-state-lock"
  }
}