terraform {
  backend "s3" {
    bucket         = "gp-terraform-bucket"
    key            = "GP-terraform-backend/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile   = true
    encrypt        = true
  }
}
