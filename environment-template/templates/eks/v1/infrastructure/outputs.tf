output "cluster_name" {
  value = module.eks_blueprints.eks_cluster_id
}

output "cluster_region" {
  value = var.environment.inputs.aws_region
}

output "configure_kubectl" {
  value = module.eks_blueprints.configure_kubectl
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "eks_cluster_id" {
  value = module.eks_blueprints.eks_cluster_id
}