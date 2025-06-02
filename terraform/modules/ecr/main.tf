resource "aws_ecr_repository" "ecr_repo" {
    name = "${var.project_name}-${var.ecr_repo_name}"
    image_tag_mutability = "MUTABLE"

    tags = {
      Name = "${var.project_name}-${var.ecr_repo_name}"
    }


  
}

resource "aws_ecr_lifecycle_policy" "ecr_ppolicy" {
  repository = aws_ecr_repository.ecr_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Remove untagged images older than 14 days",
        selection    = {
          tagStatus     = "untagged",
          countType     = "sinceImagePushed",
          countUnit     = "days",
          countNumber   = 14
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}