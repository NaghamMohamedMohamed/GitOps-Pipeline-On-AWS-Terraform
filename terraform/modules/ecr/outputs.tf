output "aws_ecr_repository_url" {
    description = "The URL of the ECR repository"
    value       = aws_ecr_repository.ecr_repo.repository_url
}

output "aws_ecr_repository_name" {
  description = "Name of the ECR repo"
  value = aws_ecr_repository.ecr_repo.name
}