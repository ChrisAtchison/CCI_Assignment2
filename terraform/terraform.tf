terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.20.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
  default_tags {
    tags = {
      Name = "cci_a2"
    }
  }
}
