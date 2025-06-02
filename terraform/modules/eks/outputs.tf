output "cluster_name" {
  description    = "The name of the EKS cluster"
    value        = aws_eks_cluster.eks_cluster.name
}
output "endpoint_public_access" {
  value = aws_eks_cluster.eks_cluster.endpoint
}