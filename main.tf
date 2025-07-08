# main.tf

# -----------------------------------------------------------------------------
# REQUIRED PROVIDERS
# Ensure these are recent and compatible with latest modules
# -----------------------------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Make sure this is 5.0 or higher. Current is 6.x.x, so "~> 5.0" is fine for 5.x, or "~> 6.0" for 6.x
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0" # Latest is 2.x
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0" # Latest is 2.x
    }
  }

  required_version = ">= 1.0.0" # This is correct for your CLI 1.12.2
}

# ... (provider "aws" block is usually here) ...

# -----------------------------------------------------------------------------
# MODULE: VPC (Networking for EKS)
# THIS MUST BE UPDATED TO THE LATEST STABLE VERSION!
# As of now (July 2025), the latest VPC module is 6.x, so "~> 6.0" is ideal.
# If you prefer sticking to 5.x, "~> 5.0" is still good.
# -----------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0" # <--- **UPDATE THIS LINE to 6.0 or later**

  name = "eks-vpc-example"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "Dev"
    Project     = "EKS-Demo"
  }
}

# -----------------------------------------------------------------------------
# MODULE: EKS CLUSTER
# THIS MUST BE UPDATED TO THE LATEST STABLE VERSION!
# As of now (July 2025), the latest EKS module is 20.x, so "~> 20.0" is ideal.
# -----------------------------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0" # <--- **UPDATE THIS LINE to 20.0 or later**

  cluster_name    = "my-demo-eks-cluster"
  cluster_version = "1.29" # Or your desired Kubernetes version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  tags = {
    Environment = "Dev"
    Project     = "EKS-Demo"
  }

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 1
      disk_size      = 20
      labels = {
        role = "general"
      }
      tags = {
        Group = "Default"
      }
    }
  }

  enable_irsa = true
  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }
}
