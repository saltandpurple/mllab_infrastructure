data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_vpc" "vpc" {
  filter {
    name = "tag:id"
    values = [var.vpc_id]
  }
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "tag:Name"
    values = ["PrivateSubnet-*"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
