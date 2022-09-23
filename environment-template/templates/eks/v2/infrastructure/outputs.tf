output "cluster_region" {
  value = var.environment.inputs.aws_region
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = jsonencode(join(",", module.vpc.public_subnets))
}

output "private_subnets" {
  value = jsonencode(join(",", module.vpc.private_subnets))
}

output "eks_cluster_id" {
  value = module.eks_blueprints.eks_cluster_id
}
