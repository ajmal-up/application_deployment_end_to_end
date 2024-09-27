# -----------------------------------------------------------------------------
# Terraform Outputs File
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Outputs related to the EKS Cluster
# -----------------------------------------------------------------------------
output "eks_cluster_name" {
  value       = module.eks.cluster_id
  description = "EKS cluster name"
}

# -----------------------------------------------------------------------------
# Read Only Outputs
# -----------------------------------------------------------------------------
output "readonly_access_key" {
  value       = module.readonly_iam_user.iam_access_key_id
  description = "Read only user access key"
}

output "readonly_secret_access_key" {
  sensitive   = true
  value       = module.readonly_iam_user.iam_access_key_secret
  description = "Read only user secret key"
}

# -----------------------------------------------------------------------------
# Edit Access Outputs
# -----------------------------------------------------------------------------
output "edit_access_key" {
  value       = module.edit_access_iam_user.iam_access_key_id
  description = "Edit user access key"
}

output "edit_secret_access_key" {
  sensitive   = true
  value       = module.edit_access_iam_user.iam_access_key_secret
  description = "Edit user secret key"
}