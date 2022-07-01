

terraform {
  required_version = ">=1.1.5"

  backend "s3" {
    bucket         = "peer-vpc-tf-12"
    dynamodb_table = "terraform-lock"
    key            = "path/env"
    region         = "us-east-1"
    encrypt        = "true"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# requester provider block
provider "aws" {
  region = local.aws_region

  assume_role {
    role_arn = "arn:aws:iam::${lookup(var.env, terraform.workspace)}:role/Terraform_Admin_Role"
  }
}

# accepter provider block
provider "aws" {
alias = "accepter"
  region = local.aws_region

  assume_role {
    role_arn = "arn:aws:iam::${lookup(var.env, terraform.workspace)}:role/Terraform_Admin_Role"
  }
}
# prod vpc infor
data "terraform_remote_state" "operational_prod" {
    backend = "s3"
 
   config = {
       region = "us-east-1"
       bucket = "kojitechs-deploy-vpcchildmodule.tf-12"
       key = "env:/prod/path/env"
   }
}

# dev vpc info
data "terraform_remote_state" "operational_dev" {
    backend = "s3"
 
   config = {
       region = "us-east-1"
       bucket = "kojitechs-deploy-vpcchildmodule.tf-12"
       key = "env:/dev/path/env"
   }
}

locals {
  operation_env_prod = data.terraform_remote_state.operational_prod.outputs
  operation_env_dev = data.terraform_remote_state.operational_dev.outputs
  prod_vpc_id = local.operation_env_prod.vpc_id
  dev_vpc_id = local.operation_env_dev.vpc_id
  aws_region = var.aws_region
}

module "vpc_peering_cross_account" {
  source = "cloudposse/vpc-peering-multi-account/aws"

  namespace = terraform.workspace
  stage     = "dev"
  name      = "cluster"

  requester_aws_assume_role_arn             = "arn:aws:iam::${lookup(var.env, terraform.workspace)}:role/Terraform_Admin_Role"
  requester_region                          = local.aws_region
  requester_vpc_id                          = local.prod_vpc_id
  requester_allow_remote_vpc_dns_resolution = true

  accepter_aws_assume_role_arn             =  "arn:aws:iam::${var.accepter_account_id}:role/Terraform_Admin_Role"
  accepter_region                          = local.aws_region
  accepter_vpc_id                          = local.dev_vpc_id
  accepter_allow_remote_vpc_dns_resolution = true
}