# -----------------------------------------------------------------------------
# Create EKS IAM POLICY
# -----------------------------------------------------------------------------
# Module to create an IAM policy allowing EKS cluster access
module "allow_eks_access_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.3.1"

  # Name of the IAM policy
  name          = "${local.name}-allow-eks-access"
  create_policy = var.eks_iam_access_policy # Specify if IAM policy should be created
  description   = "EKS Allow IAM Policy"

  # IAM policy document specifying permissions
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["eks:DescribeCluster"]
        Effect   = "Allow"
        Resource = "*" # Allow action on any resource
      },
    ]
  })
}

# -----------------------------------------------------------------------------
# Create EKS IAM ROLE
# -----------------------------------------------------------------------------
# Module to create an IAM role for EKS administrators
module "eks_admin_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.3.1"

  # Name of the IAM role
  role_name         = "${local.name}-eks-admin"
  create_role       = true  # Specify if IAM role should be created
  role_requires_mfa = false # Specify if MFA is required for the IAM role

  # Attach custom IAM policies to the IAM role
  custom_role_policy_arns = [module.allow_eks_access_iam_policy.arn]

  # List of trusted entities (roles/accounts) that can assume this role
  trusted_role_arns = [
    "arn:aws:iam::${module.vpc.vpc_owner_id}:root"
  ]
}

# -----------------------------------------------------------------------------
# Create EKS READ ONLY USER
# -----------------------------------------------------------------------------
# Module to create an IAM user with read-only access
module "readonly_iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "5.3.1"

  # Name of the IAM user
  name                          = "${local.name}-readonly_user"
  create_iam_access_key         = true  # Specify if IAM access key should be created
  create_iam_user_login_profile = false # Specify if IAM user login profile should be created
  force_destroy                 = true  # Allow the IAM user to be destroyed even with non-Terraform-managed IAM access keys, login profile, or MFA devices
}

# -----------------------------------------------------------------------------
# Create EKS EDIT USER
# -----------------------------------------------------------------------------
# Module to create an IAM user with edit access
module "edit_access_iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "5.3.1"

  # Name of the IAM user
  name                          = "${local.name}-edit_user"
  create_iam_access_key         = true  # Specify if IAM access key should be created
  create_iam_user_login_profile = false # Specify if IAM user login profile should be created
  force_destroy                 = true  # Allow the IAM user to be destroyed even with non-Terraform-managed IAM access keys, login profile, or MFA devices
}

# -----------------------------------------------------------------------------
# Create EKS ADMIN IAM POLICY
# -----------------------------------------------------------------------------
# Module to create an IAM policy allowing assuming the EKS admin role
module "allow_assume_eks_admins_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.3.1"

  # Name of the IAM policy
  name          = "${local.name}-allow-assume-eks-admin-iam-role"
  create_policy = true # Specify if IAM policy should be created

  # IAM policy document specifying permissions
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        # Allow assuming the specified IAM role
        Resource = module.eks_admin_iam_role.iam_role_arn
      },
    ]
  })
}

# -----------------------------------------------------------------------------
# Create EKS AIM GROUP WITH POLICIES
# -----------------------------------------------------------------------------
# Module to create an IAM group with policies for EKS admins
module "eks_admins_iam_group" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "5.3.1"

  # Name of the IAM group
  name         = "${local.name}-eks-admin"
  create_group = true # Specify if IAM group should be created

  # List of IAM users to include in the IAM group
  group_users = [module.readonly_iam_user.iam_user_name, module.edit_access_iam_user.iam_user_name]

  # Attach custom IAM policies to the IAM group
  custom_group_policy_arns = [module.allow_assume_eks_admins_iam_policy.arn, module.allow_eks_access_iam_policy.arn]
}
