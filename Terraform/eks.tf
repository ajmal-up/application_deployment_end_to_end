# -----------------------------------------------------------------------------
# Create EKS Cluster
# -----------------------------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws" # Module source specifying the use of the EKS module from the terraform-aws-modules repository
  version = "19.21.0"                       # Version of the EKS module to be used

  # Input parameters for the EKS module
  cluster_name                    = local.name                 # Unique name for the EKS cluster
  cluster_version                 = var.kubernetes_version     # Version of Kubernetes to use for the EKS cluster
  cluster_endpoint_private_access = var.eks_private_access     # Boolean flag for private access to the EKS cluster
  cluster_endpoint_public_access  = var.eks_public_access      # Boolean flag for public access to the EKS cluster
  vpc_id                          = module.vpc.vpc_id          # ID of the VPC where the EKS cluster will be created
  subnet_ids                      = module.vpc.private_subnets # List of subnet IDs for the EKS cluster
  enable_irsa                     = var.eks_irsa               # Boolean flag for enabling IAM Roles for Service Accounts (IRSA)
  eks_managed_node_groups         = var.eks_cluster_nodegroups # Configuration for managed node groups

  # AWS authentication configurations for managing access to the EKS cluster
  manage_aws_auth_configmap = true # Boolean flag to manage AWS auth config map for Kubernetes
  aws_auth_roles = [
    {
      rolearn  = module.eks_admin_iam_role.iam_role_arn  # IAM role ARN for EKS admin
      username = module.eks_admin_iam_role.iam_role_name # IAM role name for EKS admin
      groups   = ["system:masters"]                      # Kubernetes groups for EKS admin
    },
  ]
  aws_auth_users = [
    {
      userarn  = module.readonly_iam_user.iam_user_arn  # IAM user ARN for readonly user
      username = module.readonly_iam_user.iam_user_name # IAM user name for readonly user
      groups   = ["developer"]                          # Kubernetes groups for readonly user
    },
    {
      userarn  = module.edit_access_iam_user.iam_user_arn  # IAM user ARN for edit access user
      username = module.edit_access_iam_user.iam_user_name # IAM user name for edit access user
      groups   = ["edit"]                                  # Kubernetes groups for edit access user
    },
  ]

  # Node Security Group Configurations
  node_security_group_additional_rules = {
    # Example additional rules for EKS node security group
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    ingress_cluster_to_node_all_traffic = {
      description                   = "Cluster API to Nodegroup all traffic"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  # Cluster Tags
  tags = local.tags # Tags to be applied to the EKS cluster for better organization
}

# -----------------------------------------------------------------------------
# Retrieve EKS Cluster Information
# -----------------------------------------------------------------------------
# Data block to fetch information about the created EKS cluster
data "aws_eks_cluster" "default" {
  name       = module.eks.cluster_name # Name of the EKS cluster to retrieve information about
  depends_on = [module.eks.cluster_name]
}

# -----------------------------------------------------------------------------
# Retrieve EKS Cluster Authentication Data
# -----------------------------------------------------------------------------
# Data block to fetch authentication data for the EKS cluster
data "aws_eks_cluster_auth" "default" {
  name = module.eks.cluster_name # Name of the EKS cluster to retrieve authentication data for
}

# -----------------------------------------------------------------------------
# Configure Kubernetes Provider
# -----------------------------------------------------------------------------
# Provider block for the Kubernetes provider to interact with the EKS cluster
provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint                                    # EKS cluster endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data) # EKS cluster CA certificate
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.default.id]
    command     = "aws"
  }
}
