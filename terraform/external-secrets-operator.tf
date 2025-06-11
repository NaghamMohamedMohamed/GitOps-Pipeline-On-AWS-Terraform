# ------------------------------------------------------------

#                     AWS secretsmanager secrets

# ------------------------------------------------------------

# 1. MySQL Secret
resource "aws_secretsmanager_secret" "mysql" {
  name = "${var.project_name}-mysql-secret"
  description = "MySQL credentials for NodeJS app"
}

resource "aws_secretsmanager_secret_version" "mysql" {
  secret_id     = aws_secretsmanager_secret.mysql.id
  secret_string = jsonencode({
    username = var.mysql_username
    password = var.mysql_password
    mysql-root-password = var.mysql_password
  })
}

# 2. Redis Secret
resource "aws_secretsmanager_secret" "redis" {
  name = "${var.project_name}-redis-secret"
  description = "Redis credentials for NodeJS app"
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id     = aws_secretsmanager_secret.redis.id
  secret_string = jsonencode({
    password = var.redis_password
  })
}

# ------------------------------------------------------------

#                     Custom ESO Policy

# ------------------------------------------------------------
resource "aws_iam_policy" "eso_policy" {
  name        = "ESOAccessPolicy"
  description = "Policy for External Secrets Operator to access AWS Secrets Manager"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
            "secretsmanager:GetResourcePolicy",
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
            "secretsmanager:ListSecretVersionIds"
        ],
        Resource = "*"
      }
    ]
  })
}
# ------------------------------------------------------------

#                 ESO Role, Assume Role, Attachement

# ------------------------------------------------------------
data "aws_iam_policy_document" "eso_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:app:external-secrets-sa"]
    }

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
  }
}

resource "aws_iam_role" "eso_role" {
  name               = "ESOAccessRole"
  assume_role_policy = data.aws_iam_policy_document.eso_trust.json
}

resource "aws_iam_role_policy_attachment" "eso_policy_attachment" {
  role       = aws_iam_role.eso_role.name
  policy_arn = aws_iam_policy.eso_policy.arn
}