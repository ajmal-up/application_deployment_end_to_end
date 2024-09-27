# -----------------------------------------------------------------------------
# DEFINE VARIABLES FOR REUSABILITY
# -----------------------------------------------------------------------------

variable "prefix" {
  default     = "managing-eks-terraform"
  type        = string
  description = "Common prefix for AWS resources names"
}

variable "cluster_name" {
  type        = string
  description = "cluster name of env"
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region to deploy VPC"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.10.0.0/16"
  description = "AWS VPC CIDR range"
}

variable "environment" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.30"
}

variable "eks_cluster_nodegroups" {
  description = "Nodegroups of the EKS cluster"
}

variable "eks_public_access" {
  description = "EKS Public access"
  type        = bool
  default     = true
}

variable "eks_private_access" {
  description = "EKS Private access"
  type        = bool
  default     = false
}

variable "eks_irsa" {
  description = "Enable IAM Roles for Service Accounts (IRSA) on the EKS cluster"
  type        = bool
  default     = true
}

variable "eks_iam_access_policy" {
  description = "Enable EKS Access IAM policy"
  type        = bool
  default     = true
}

variable "node_security_group_additional_rules" {
  description = "Additional rules for the EKS node security group"
  type        = map(any)
  default = {
  }
}