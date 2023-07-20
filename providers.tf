
locals {
  aws_region     = "us-west-2"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = "= 1.2.4"

  #   backend "s3" {
#     bucket   = "genies-terraform"
#     key      = "qa/${path_relative_to_include()}/terraform.tfstate"
#     region   = "us-west-2"
#   }

}

provider "aws" {
  region              = "${local.aws_region}"
}