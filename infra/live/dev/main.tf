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
    encrypt        = true [cite: 2]
    dynamodb_table = "lgtm-engineer-challenge-tf-lock" 
  }
  */

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # NEW: Helm provider is required to deploy charts
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13" 
    }
    # NEW: Kubernetes provider is often required for dependencies (like namespaces)
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# ----------------------------------------------------
# AWS Provider Configuration
# ----------------------------------------------------
provider "aws" {
  region  = "ap-southeast-2"
  profile = "default"
}

# ----------------------------------------------------
# NEW: Kubernetes and Helm Provider Configuration
# ----------------------------------------------------

# Configure the Kubernetes provider to connect to the EKS cluster.
# This relies on the output from the EKS module.
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "auth" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.auth.token
  # Wait for the EKS cluster to be active before trying to connect
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# The Helm provider uses the configured Kubernetes provider implicitly.
provider "helm" {
  # The Helm provider will now automatically use the configuration from the
  # 'kubernetes' provider block defined just above it.
}


# ----------------------------------------------------
# MODULES: VPC and EKS Cluster (Contents unchanged)
# ----------------------------------------------------

# 1. VPC Module (Creates Networking components)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0" 

  name = "lgtm-vpc-dev"
  
  cidr = "10.0.0.0/16" [cite: 4]

  azs                  = ["ap-southeast-2a", "ap-southeast-2b"]
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets       = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true 
  enable_dns_hostnames = true

  tags = {
    Name        = "lgtm-vpc-dev"
    Environment = "dev"
  }
}

# 2. EKS Cluster Module
module "eks" {
  source = "terraform-aws-modules/eks/aws" [cite: 5]
  version = "~> 20.0" 

  cluster_name    = "lgtm-eks-dev"
  cluster_version = "1.28" 
  
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # EKS Node Group
  eks_managed_node_groups = {
    default = {
      disk_size      = 20 [cite: 6]
      instance_types = ["t3.medium"] 
      min_size       = 1
      max_size       = 2
      desired_size   = 1
    }
  }
}


# ----------------------------------------------------
# NEW: Platform Deployment (ArgoCD and Observability)
# ----------------------------------------------------

# Load the environment-specific values file
locals {
  argocd_values         = fileexists("${path.module}/values-dev.yaml") ? yamldecode(file("${path.module}/values-dev.yaml")) : {}
}

# 3. ArgoCD Deployment (Using Official Helm Chart)
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.54.3" # Pin a stable version

  # Pass the ArgoCD section from the loaded values-dev.yaml
  values = [
    yamlencode(lookup(local.argocd_values, "argocd", {}))
  ]

  # Depend on the EKS cluster being fully active
  depends_on = [
    module.eks
  ]
}

# 4. Observability Stack Deployment (Using Custom Wrapper Chart)
resource "helm_release" "observability" {
  name             = "observability"
  # Reference the local custom chart defined in the 'charts/' directory
  chart            = "../../charts/observability" 
  namespace        = "observability"
  create_namespace = true
  
  # Pass the Observability section from the loaded values-dev.yaml
  values = [
    yamlencode(lookup(local.argocd_values, "observability", {}))
  ]
  
  # Deploy after ArgoCD (as ArgoCD might manage it later)
  depends_on = [
    helm_release.argocd
  ]
}

# ----------------------------------------------------
# OUTPUTS (Contents unchanged)
# ----------------------------------------------------
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_arn" {
  value = module.eks.cluster_arn
}