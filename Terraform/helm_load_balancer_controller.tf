# -----------------------------------------------------------------------------
# AWS Load Balancer Controller IRSA Role Module
# -----------------------------------------------------------------------------
module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.1"

  # Unique name for the AWS Load Balancer Controller IRSA role
  role_name = "${local.name}-aws-load-balancer-controller"

  # Indicates whether to attach the Load Balancer Controller policy to the IAM role
  attach_load_balancer_controller_policy = true

  # Configures OIDC provider for AWS EKS cluster
  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# -----------------------------------------------------------------------------
# Helm Release for AWS Load Balancer Controller
# -----------------------------------------------------------------------------
resource "helm_release" "aws_load_balancer_controller" {
  # Unique name for the Helm release
  name = "aws-load-balancer-controller"

  # Chart details for AWS Load Balancer Controller
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.4.4"

  # Set values for the Helm release
  set {
    name  = "replicaCount"
    value = 1
  }

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_load_balancer_controller_irsa_role.iam_role_arn
  }
}
