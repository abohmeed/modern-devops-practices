terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.50"
    }
  }
}
provider "aws" {
  profile = "terraform"
  assume_role {
    role_arn     = "arn:aws:iam::790250078024:role/Test-Role"
    session_name = "AWS-Session"
  }
}

