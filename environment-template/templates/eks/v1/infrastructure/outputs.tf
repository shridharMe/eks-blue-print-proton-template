
output "cluster_name" {
  value = module.eks_blueprints.eks_cluster_id
}

output "cluster_region" {
  value = var.environment.inputs.aws_region
}

output "configure_kubectl" {
  value = module.eks_blueprints.configure_kubectl
}

output "module_version" {
  value = module.eks_blueprints.configure_kubectl
}

