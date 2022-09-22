terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.14.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~>2.2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
  }
  required_version = "~>1.0"
}

provider "aws" {
  region = var.environment.outputs.cluster_region
}

data "aws_eks_cluster" "cluster" {
  name = var.environment.outputs.eks_cluster_id
  vpc_config {
    vpc_id=var.environment.outputs.vpc_id
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.environment.outputs.eks_cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
