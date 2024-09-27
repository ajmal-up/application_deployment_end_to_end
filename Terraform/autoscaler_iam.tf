# -----------------------------------------------------------------------------
# Create IAM Role for Cluster Autoscaler with IRSA
# -----------------------------------------------------------------------------
/*
  Purpose: 
  This module is designed to create an IAM role for the Cluster Autoscaler with IRSA enabled. 
  IRSA allows Kubernetes pods to assume IAM roles directly, providing secure AWS resource access. 
  The role created here is specifically configured to work with the Cluster Autoscaler in the kube-system namespace of the EKS cluster. 
*/

module "cluster_autoscaler_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.1"

  # Role name for the IAM role to be created
  role_name = "${local.name}-cluster-autoscaler"

  # Flag to attach the Cluster Autoscaler IAM policy to the role
  attach_cluster_autoscaler_policy = true

  # List of EKS cluster names to associate with the IAM role
  cluster_autoscaler_cluster_ids = [module.eks.cluster_name]

  # OIDC provider configuration for IRSA
  oidc_providers = {
    ex = {
      # OIDC provider ARN associated with the EKS cluster
      provider_arn = module.eks.oidc_provider_arn
      # Namespace and service accounts for which this role will be assumed
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}
