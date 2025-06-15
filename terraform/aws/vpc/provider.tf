terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
    awsutils = {
      source  = "cloudposse/awsutils"
      version = "~>0.19"
    }
  }
}

provider aws {
  region = "eu-central-1"
  profile = "df"
}
