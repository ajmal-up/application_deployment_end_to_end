# -----------------------------------------------------------------------------
# Create VPC
# -----------------------------------------------------------------------------

# Fetch AZs in the current region
# The following data block retrieves information about available availability zones in the current region
data "aws_availability_zones" "available" {
}

# Module block to create the VPC
module "vpc" {
  # Module source and version information
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  # Input parameters for the VPC module
  name = local.name     # Name of the VPC
  cidr = local.vpc_cidr # CIDR block for the VPC
  azs  = local.azs      # List of availability zones in the region

  # Subnet configurations using local variables and cidrsubnet function
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]

  # NAT Gateway configurations
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # DNS configurations
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags for the VPC resources
  tags = local.tags
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

