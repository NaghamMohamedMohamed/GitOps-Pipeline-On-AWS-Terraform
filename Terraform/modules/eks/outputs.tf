output "cluster_name" {
  description    = "The name of the EKS cluster"
    value        = aws_eks_cluster.eks_cluster.name
}
output "endpoint_public_access" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "jenkins_irsa_role_arn" {
  description = "The ARN of the Jenkins IRSA role"
  value       = aws_iam_role.gp_ebs_addon_role.arn
  
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  value = aws_iam_openid_connect_provider.eks.url
}
