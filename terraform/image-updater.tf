# ------------------------------------------------------------

#                     Custom image_updater Policy

# ------------------------------------------------------------
resource "aws_iam_policy" "image_updater_policy" {
  name        = "ImageUpdaterAccessPolicy"
  description = "Policy for Image Updater to access ECR"
  policy      = jsonencode({
    "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:ListImages"
      ],
      "Resource": "*"
      }
    ]
  })
}
# ------------------------------------------------------------

#                 ESO Role, Assume Role, Attachement

# ------------------------------------------------------------
data "aws_iam_policy_document" "image_updater_trust" {
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
      values   = ["system:serviceaccount:argocd:image-updater-sa"]
    }

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
  }
}

resource "aws_iam_role" "image_updater_role" {
  name               = "ImageUpdaterAccessRole"
  assume_role_policy = data.aws_iam_policy_document.image_updater_trust.json
}

resource "aws_iam_role_policy_attachment" "image_updater_policy_attachment" {
  role       = aws_iam_role.image_updater_role.name
  policy_arn = aws_iam_policy.image_updater_policy.arn
}