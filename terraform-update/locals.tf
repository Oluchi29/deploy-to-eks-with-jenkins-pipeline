
locals {
  name = "eks-terraform-cluster"
  tags = {
    Environment = "dev"
    Project     = "eks-terraform-deploy"
  }
}