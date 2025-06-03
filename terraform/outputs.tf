output "aws_ecr_repository_url" {
    description = "The URL of the ECR repository"
    value       = module.ecr.aws_ecr_repository_url
}

output "aws_ecr_repository_name" {
  description = "Name of the ECR repo"
  value = module.ecr.aws_ecr_repository_name
}

output "cluster_name" {
  description    = "The name of the EKS cluster"
    value        = module.eks.cluster_name
}
output "endpoint_public_access" {
  value = module.eks.endpoint_public_access
}

output "public_subnet_ids_list" {
  description    = "List of public subnet ids"
  value = module.network.public_subnet_ids_list
}


output "private_subnet_ids_list" {
  description    = "List of private subnet ids"
  value = module.network.private_subnet_ids_list
}

output "jenkins_irsa_role_arn" {
  description = "The ARN of the Jenkins IRSA role"
  value       = module.eks.jenkins_irsa_role_arn
  
}