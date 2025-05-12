terraform {
  backend "s3" {
    bucket = "oluchi-data-bucket-2025"
    key    = "eks/terraform.tfstate"
    region = "us-east-1"
  }
}