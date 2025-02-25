output "access-entries" {
 value = module.dev-eks-cluster.access_entries
}

output "cluster-addons" {
  value = module.dev-eks-cluster.cluster_addons
}

output "log-group" {
  value = module.dev-eks-cluster.cloudwatch_log_group_name
}

output "cluster-iam-role" {
  value = module.dev-eks-cluster.cluster_iam_role_name
}

output "cluster-endpoint" {
  value = module.dev-eks-cluster.cluster_endpoint
}

output "cluster-status" {
  value = module.dev-eks-cluster.cluster_status
}

output "cluster-version" {
  value = module.dev-eks-cluster.cluster_version
}

output "cluster-id-provider" {
  value = module.dev-eks-cluster.cluster_identity_providers
}