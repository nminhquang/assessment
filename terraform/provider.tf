provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.application_name
      Terraform   = "true"
    }
  }
}