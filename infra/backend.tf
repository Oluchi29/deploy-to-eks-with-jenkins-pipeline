terraform {
  backend "s3" {
    bucket = "demo-bucket-2010"
    region = "us-east-1"
    key    = "rubi1-backend/terraform.tfstate"
  }
}