terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.34.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"
  azs  = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"  # Stable version

  cluster_name    = "demo-java-cluster"
  cluster_version = "1.29"

  subnets = module.vpc.private_subnets
  vpc_id  = module.vpc.vpc_id

  enable_irsa = true

  worker_groups = [
    {
      name                 = "app-nodes"
      instance_type        = "t3.medium"
      asg_desired_capacity = 2
      asg_min_size         = 1
      asg_max_size         = 2
    }
  ]
}
