variable "project_name" {
  default = "gitops-gp"
}

variable "ecr_repo_name" {
  default = "ecr"
}
# ----------------------------------------------------------

#                     network module

# ----------------------------------------------------------

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}

variable "availability_zone" {
  default = "us-east-1a"
}
# ----------------------------------------------------------

#                     External Secrets Operator

# ----------------------------------------------------------

variable "mysql_username" {
  description = "Username for MySQL database"
  type        = string
  sensitive   = true
}

variable "mysql_password" {
  description = "Password for MySQL database"
  type        = string
  sensitive   = true
}

variable "redis_password" {
  description = "Password for Redis"
  type        = string
  sensitive   = true
}
