locals {
  # The name includes the cluster name and Terraform workspace
  name = "${var.cluster_name}-${terraform.workspace}"

  # Node group name for managed on-demand instances
  node_group_name = "managed-ondemand"

  # VPC CIDR block
  vpc_cidr = var.vpc_cidr

  # Availability zones sliced from the data source
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  # Tags to be applied to resources
  tags = {
    Environment = var.environment
    app         = "${var.cluster_name}-${terraform.workspace}"
  }
}
