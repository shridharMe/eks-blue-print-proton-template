locals {
  #local_data = jsondecode(file("${path.module}/proton.auto.tfvars.json"))
  instance_types =   splt(",",var.environment.inputs.managed_node_groups_instance_types)
  private_subnets_cidrs =   splt(",",var.environment.inputs.private_subnets_cidrs)
  public_subnets_cidrs =   splt(",",var.environment.inputs.public_subnets_cidrs)
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
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.0.2"

  # EKS CLUSTER
  cluster_version           = var.environment.inputs.cluster_version #"1.21"
  vpc_id                    = module.vpc.vpc_id                              
  private_subnet_ids        = module.vpc.private_subnets     
  cluster_name              = var.environment.inputs.cluster_name

  # EKS MANAGED NODE GROUPS
  managed_node_groups = {
    mg_m5 = {
      node_group_name = var.environment.inputs.managed_node_groups_name
      instance_types  = local.instance_types
      subnet_ids      = module.vpc.private_subnets
    }
  }
}
// managed_node_groups_instance_types managed_node_groups_name

module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.0.2"

  eks_cluster_id = module.eks_blueprints.eks_cluster_id

  # EKS Addons
  enable_amazon_eks_vpc_cni            = true
  enable_amazon_eks_coredns            = true
  enable_amazon_eks_kube_proxy         = true
  enable_amazon_eks_aws_ebs_csi_driver = true

  #K8s Add-ons
  enable_argocd                       = true
  enable_aws_for_fluentbit            = true
  enable_aws_load_balancer_controller = true
  enable_cluster_autoscaler           = true
  enable_metrics_server               = true
  enable_prometheus                   = true
}