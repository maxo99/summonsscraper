# OpenTofu version and required providers
terraform {
  required_version = ">= 1.6"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Optional: Configure remote state storage
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "summonsscraper/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "summonsscraper"
      Environment = var.environment
      ManagedBy   = "opentofu"
    }
  }
}
