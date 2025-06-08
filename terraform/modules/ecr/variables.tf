variable "project_name" {
  type = string
}

variable "ecr_repo_name" {
  type        = string
  description = "The name of the ECR repository"
  
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS OIDC provider"
}

variable "oidc_provider_url" {
  type        = string
  description = "URL of the EKS OIDC provider"
}
