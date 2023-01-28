terraform {
  backend "s3" {
    bucket         = "moderndevops-terraform-state"
    key            = "terraform-state"
    region         = "eu-west-1"
    dynamodb_table = "Terraform-backend-lock"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.50"
    }
  }
}
provider "aws" {
  profile = "terraform"
  region  = "eu-west-1"
  assume_role {
    role_arn     = "arn:aws:iam::790250078024:role/terraform-role"
    session_name = "AWS-Session"
  }
}

