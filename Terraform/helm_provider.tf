# -----------------------------------------------------------------------------
# Helm Provider Configuration
# -----------------------------------------------------------------------------
provider "helm" {
  # -----------------------------------------------------------------------------
  # Kubernetes Configuration
  # -----------------------------------------------------------------------------
  kubernetes {
    # The address of the Kubernetes cluster API server
    host = data.aws_eks_cluster.default.endpoint

    # Base64-encoded PEM-format certificate authority data for connecting to the Kubernetes cluster
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)

    # Exec-based authentication for AWS EKS cluster
    exec {
      # API version for the exec authentication mechanism
      api_version = "client.authentication.k8s.io/v1beta1"

      # Arguments for the exec command
      args = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.default.id]

      # Command to execute for authentication
      command = "aws"
    }
  }
}
