terraform {
  backend "s3" {
    bucket = "terra-wordpress-eks-bucket"
    key    = "terraform/state"
    region = "us-east-1"
  }
}