# -----------------------------------------------------------------------------
# Create manifests for Cluster Autoscaler 
# -----------------------------------------------------------------------------


# This provider block configures the "kubectl" provider to interact with the EKS cluster.
# It retrieves the cluster endpoint and certificate from the AWS EKS data source and uses the AWS CLI to get a token for authentication.
provider "kubectl" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.default.id]
    command     = "aws"
  }
}

# This resource defines a Kubernetes ServiceAccount manifest using the kubectl provider.
# Annotation links the ServiceAccount to an IAM role (IRSA) for the Cluster Autoscaler.
resource "kubectl_manifest" "service_account" {
  yaml_body = <<-EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
  name: cluster-autoscaler
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: ${module.cluster_autoscaler_irsa_role.iam_role_arn} 
EOF
}

# This resource defines a Kubernetes Role manifest using the kubectl provider.
# The Role provides the necessary permissions for the Cluster Autoscaler to access ConfigMaps.
resource "kubectl_manifest" "role" {
  yaml_body = <<-EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["create","list","watch"]
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["cluster-autoscaler-status", "cluster-autoscaler-priority-expander"]
    verbs: ["delete", "get", "update", "watch"]
EOF
}

# This resource defines a RoleBinding manifest to bind the ServiceAccount to the Role defined above.
# The RoleBinding allows the "cluster-autoscaler" ServiceAccount to use the permissions of the Role.
resource "kubectl_manifest" "role_binding" {
  yaml_body = <<-EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: cluster-autoscaler
subjects:
  - kind: ServiceAccount
    name: cluster-autoscaler
    namespace: kube-system
EOF
}

# This resource defines a ClusterRole manifest with permissions across the cluster.
# The ClusterRole provides the necessary permissions for the Cluster Autoscaler to function.
resource "kubectl_manifest" "cluster_role" {
  yaml_body = <<-EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-autoscaler
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
rules:
  - apiGroups: [""]
    resources: ["events", "endpoints"]
    verbs: ["create", "patch"]
  - apiGroups: [""]
    resources: ["pods/eviction"]
    verbs: ["create"]
  - apiGroups: [""]
    resources: ["pods/status"]
    verbs: ["update"]
  - apiGroups: [""]
    resources: ["endpoints"]
    resourceNames: ["cluster-autoscaler"]
    verbs: ["get", "update"]
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["watch", "list", "get", "update"]
  - apiGroups: [""]
    resources:
      - "namespaces"
      - "pods"
      - "services"
      - "replicationcontrollers"
      - "persistentvolumeclaims"
      - "persistentvolumes"
    verbs: ["watch", "list", "get"]
  - apiGroups: ["extensions"]
    resources: ["replicasets", "daemonsets"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["policy"]
    resources: ["poddisruptionbudgets"]
    verbs: ["watch", "list"]
  - apiGroups: ["apps"]
    resources: ["statefulsets", "replicasets", "daemonsets"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["batch", "extensions"]
    resources: ["jobs"]
    verbs: ["get", "list", "watch", "patch"]
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["create"]
  - apiGroups: ["coordination.k8s.io"]
    resourceNames: ["cluster-autoscaler"]
    resources: ["leases"]
    verbs: ["get", "update"]
EOF
}

# This resource defines a ClusterRoleBinding manifest to bind the ClusterRole to the ServiceAccount.
# The ClusterRoleBinding allows the "cluster-autoscaler" ServiceAccount to use the permissions of the ClusterRole.
resource "kubectl_manifest" "cluster_role_binding" {
  yaml_body = <<-EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-autoscaler
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-autoscaler
subjects:
  - kind: ServiceAccount
    name: cluster-autoscaler
    namespace: kube-system
EOF
}

# This resource defines a Deployment manifest for the Cluster Autoscaler.
# It deploys a single replica of the Cluster Autoscaler pod in the "kube-system" namespace.
resource "kubectl_manifest" "deployment" {
  yaml_body = <<-EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  labels:
    app: cluster-autoscaler
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
    spec:
      priorityClassName: system-cluster-critical
      securityContext:
        runAsNonRoot: true
        runAsUser: 65534
        fsGroup: 65534
      serviceAccountName: cluster-autoscaler  
      containers:
        - image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.23.1
          name: cluster-autoscaler
          resources:
            limits:
              cpu: 100m
              memory: 600Mi
            requests:
              cpu: 100m
              memory: 600Mi
          command:
            - ./cluster-autoscaler
            - --v=4
            - --stderrthreshold=info
            - --cloud-provider=aws
            - --skip-nodes-with-local-storage=false
            - --expander=least-waste
            - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${module.eks.cluster_name}
          volumeMounts:
            - name: ssl-certs
              mountPath: /etc/ssl/certs/ca-certificates.crt
              readOnly: true
      volumes:
        - name: ssl-certs
          hostPath:
            path: "/etc/ssl/certs/ca-bundle.crt"
EOF
}

# This resource creates a ClusterRole named "dev_user" in the Kubernetes cluster using the kubectl provider.
# The ClusterRole grants permissions to developers or associated members on various resources across all API groups.
resource "kubectl_manifest" "cluster_role_developer" {
  yaml_body = <<-EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: developer
rules:
- apiGroups: ["*"]
  resources: ["deployments", "configmaps", "pods","pods/log", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch" , "delete"]
EOF
}

