provider "aws" {
  region = "us-east-1"
}


# ----------------------------------------------------------

#                     network module

# ----------------------------------------------------------


module "network" {
  source               = "./modules/network"
  vpc_cidr             = var.vpc_cidr
  public_subnets = {
    public-1 = {
      cidr_block = "10.0.1.0/24"
      az         = "us-east-1a"
    }
    public-2 = {
      cidr_block = "10.0.2.0/24"
      az         = "us-east-1b"
    }
      public-3 = {
      cidr_block = "10.0.3.0/24"
      az         = "us-east-1c"
    }
  }

  private_subnets = {
    private-1 = {
      cidr_block = "10.0.4.0/24"
      az         = "us-east-1a"
    }
    private-2 = {
      cidr_block = "10.0.5.0/24"
      az         = "us-east-1b"
    }
    private-3 = {
      cidr_block = "10.0.6.0/24"
      az         = "us-east-1c"
    }
  }
  project_name         = var.project_name
}


# ----------------------------------------------------------

#                     EKS module

# ----------------------------------------------------------

module "eks" {
  source = "./modules/eks"
  private_subnet_ids = module.network.private_subnet_ids_list
  project_name = var.project_name
}