# -----------------------------------------------------------------------------
# Helm Release for Metrics Server
# -----------------------------------------------------------------------------
resource "helm_release" "metrics_server" {
  # Unique name for the Helm release
  name = "metrics-server"

  # Chart details for Metrics Server
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "metrics-server"
  namespace  = "metrics-server"
  version    = "6.2.13"

  # Create the namespace if it does not exist
  create_namespace = true

  # Set values for the Helm release
  set {
    name  = "apiService.create"
    value = "true"
  }
}
