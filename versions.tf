terraform {
  required_version = ">= 1.3.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
}
provider "aws" {

  default_tags {
    tags = {
      Environment = "Staging"
      Project     = "TerraformJenkins"
      Owner       = "Devops"
    }
  }
}
