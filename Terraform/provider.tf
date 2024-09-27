# -----------------------------------------------------------------------------
# DEFINE PROVIDER
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region
}

# -----------------------------------------------------------------------------
# REQUIRED PROVIDERS
# -----------------------------------------------------------------------------
# Configuration block for required Terraform providers and their versions
terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.6.0"
    }
  }
  # Terraform version constraint to ensure compatibility
  required_version = "~> 1.0"
}
