terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}


resource "aws_ecr_repository" "ecr_repo" {
    name = "${var.project_name}-${var.ecr_repo_name}"
    image_tag_mutability = "MUTABLE"

    tags = {
      Name = "${var.project_name}-${var.ecr_repo_name}"
    }


  
}

resource "aws_ecr_lifecycle_policy" "ecr_policy" {
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


resource "aws_iam_policy" "kaniko_ecr_push" {
  name        = "gp-kaniko_ecr_push"
  description = "Policy to allow pushing images to ECR from Kaniko"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ],
        Resource = "*"
      }
    ]
  })
}

data "aws_iam_openid_connect_provider" "oidc" {
  arn = var.oidc_provider_arn
}


data "aws_iam_policy_document" "kaniko_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:jenkins:kaniko-sa"]
    }

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
  }
}


resource "aws_iam_role" "kaniko_irsa_role" {
  name               = "gp-kaniko-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.kaniko_assume_role_policy.json
}


resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.kaniko_irsa_role.name
  policy_arn = aws_iam_policy.kaniko_ecr_push.arn
}