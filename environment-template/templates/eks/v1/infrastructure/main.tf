locals {
  instance_types        = split(",", var.environment.inputs.managed_node_groups_instance_types)
  private_subnets_cidrs = split(",", var.environment.inputs.private_subnets_cidrs)
  public_subnets_cidrs  = split(",", var.environment.inputs.public_subnets_cidrs)
}

module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  version         = "3.13.0"
  name            = var.environment.inputs.vpc_name
  cidr            = var.environment.inputs.vpc_cidr
  azs             = data.aws_availability_zones.available.names
  private_subnets = local.private_subnets_cidrs
  public_subnets  = local.public_subnets_cidrs

  enable_nat_gateway = true
  enable_vpn_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = var.environment.inputs.project_environment
    Project     = var.environment.inputs.project_name
  }
}


data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "region-name"
    values = [var.environment.inputs.aws_region]
  }
}


module "eks_blueprints" {
  source     = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.9.0"
  create_eks = true

  # EKS CLUSTER
  cluster_version    = var.environment.inputs.cluster_version #"1.21"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  cluster_name       = var.environment.inputs.cluster_name

  # EKS MANAGED NODE GROUPS
  managed_node_groups = {
    mg_m5 = {
      node_group_name = var.environment.inputs.managed_node_groups_name
      instance_types  = local.instance_types
      subnet_ids      = module.vpc.private_subnets
    }
  }
}



resource "time_sleep" "wait_30_seconds" {
  depends_on      = [module.eks_blueprints]
  create_duration = "30s"
}


// managed_node_groups_instance_types managed_node_groups_name
data "aws_eks_addon_version" "latest" {
  for_each = toset(["vpc-cni", "coredns"])

  addon_name         = each.value
  kubernetes_version = module.eks_blueprints.eks_cluster_version
  most_recent        = true
}

data "aws_eks_addon_version" "default" {
  for_each = toset(["kube-proxy"])

  addon_name         = each.value
  kubernetes_version = module.eks_blueprints.eks_cluster_version
  most_recent        = false
}
module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.9.0"

  eks_cluster_id       = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_blueprints.oidc_provider
  eks_cluster_version  = module.eks_blueprints.eks_cluster_version

  # EKS Addons
  enable_amazon_eks_aws_ebs_csi_driver = true
  enable_amazon_eks_vpc_cni            = true
  enable_aws_load_balancer_controller  = true
  amazon_eks_vpc_cni_config = {
    addon_version     = data.aws_eks_addon_version.latest["vpc-cni"].version
    resolve_conflicts = "OVERWRITE"
  }

  enable_amazon_eks_coredns = true
  amazon_eks_coredns_config = {
    addon_version     = data.aws_eks_addon_version.latest["coredns"].version
    resolve_conflicts = "OVERWRITE"
  }

  enable_amazon_eks_kube_proxy = true
  amazon_eks_kube_proxy_config = {
    addon_version     = data.aws_eks_addon_version.default["kube-proxy"].version
    resolve_conflicts = "OVERWRITE"
  }

  #K8s Add-ons
  enable_argocd             = var.environment.inputs.enable_argocd
  enable_aws_for_fluentbit  = var.environment.inputs.enable_aws_for_fluentbit
  enable_cert_manager       = var.environment.inputs.enable_cert_manager
  enable_cluster_autoscaler = var.environment.inputs.enable_cluster_autoscaler
  enable_karpenter          = var.environment.inputs.enable_karpenter
  enable_keda               = var.environment.inputs.enable_keda
  enable_metrics_server     = var.environment.inputs.enable_metrics_server
  enable_prometheus         = var.environment.inputs.enable_prometheus
  enable_traefik            = var.environment.inputs.enable_traefik
  enable_vpa                = var.environment.inputs.enable_vpa
  enable_yunikorn           = var.environment.inputs.enable_yunikorn
  enable_argo_rollouts      = var.environment.inputs.enable_argo_rollouts

  tags =  merge(
    var.tags,
    {
      Wait = time_sleep.wait_30_seconds.id
    }
  ) 


variable "tags" {
  type    = map(string)
  default = {}
}