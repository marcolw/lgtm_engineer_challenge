## ----------------------------------------------------
## Phase 2: Provider Configuration (Local Backend for now)
## ----------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  
  # REMOVED S3 BACKEND FOR LOCAL DEMO/PLANNING
  # Uncomment this block ONLY when ready for "terraform apply" 
  /*
  backend "s3" {
    bucket         = "lgtm-engineer-challenge-tf-state-058264095432" 
    key            = "dev/eks/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "lgtm-engineer-challenge-tf-lock" # Required for state locking!
  }
  */

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ----------------------------------------------------
# AWS Provider Configuration
# ----------------------------------------------------
provider "aws" {
  region  = "ap-southeast-2"
  profile = "default"
  # This relies on you running: aws sso login --profile default
}


# ----------------------------------------------------
# MODULES: VPC and EKS Cluster
# ----------------------------------------------------

# 1. VPC Module (Creates Networking components)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0" # Use a stable, recent version

  name = "lgtm-vpc-dev"
  cidr = "10.0.0.0/16"

  azs                  = ["ap-southeast-2a", "ap-southeast-2b"]
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets       = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true # Cost optimization for DEV
  enable_dns_hostnames = true

  tags = {
    Name        = "lgtm-vpc-dev"
    Environment = "dev"
  }
}

# 2. EKS Cluster Module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0" # Use a stable, recent version

  cluster_name    = "lgtm-eks-dev"
  cluster_version = "1.28" # Stable version
  
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # EKS Node Group (Small, Cost-Effective)
  eks_managed_node_groups = {
    default = {
      disk_size      = 20
      instance_types = ["t3.medium"] # Small, general purpose instance
      min_size       = 1
      max_size       = 2
      desired_size   = 1
    }
  }
}

# ----------------------------------------------------
# OUTPUTS
# ----------------------------------------------------
# Outputs are needed so we can connect k8s tools later
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_arn" {
  value = module.eks.cluster_arn
}