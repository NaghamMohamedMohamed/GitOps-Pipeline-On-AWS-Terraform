# ------------------------------------------------------------

#                     EKS Cluster

# ------------------------------------------------------------
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.project_name}eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}


resource "aws_eks_cluster" "eks_cluster" {
    name ="${var.project_name}-eks-cluster"

     access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.31"

  vpc_config {
    endpoint_public_access  = true
    endpoint_private_access = true
    subnet_ids = var.private_subnet_ids
     
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

# ------------------------------------------------------------

#                     EKS Node Group

# ------------------------------------------------------------
resource "aws_iam_role" "node_group_role" {
  name = "${var.project_name}eks-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "node_group_role-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "node_group_role-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "node_group_role-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group_role.name
}


resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.project_name}-eks-node-group"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = ["t2.medium"]


  depends_on = [
    aws_iam_role_policy_attachment.node_group_role-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_role-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_role-AmazonEC2ContainerRegistryReadOnly,
  ]
}

#########################################
# Jenkins IRSA Setup for EKS via Terraform
#########################################

# ----------------------------
# Data Sources
# ----------------------------
data "aws_eks_cluster" "eks" {               # Fetches EKS cluster details
  name = aws_eks_cluster.eks_cluster.name
}

data "aws_eks_cluster_auth" "eks" {          # Fetch authentication details fot EKS cluster
  name = aws_eks_cluster.eks_cluster.name
}

# ----------------------------
# TLS Certificate for OIDC Thumbprint
# ----------------------------
# For the TLS certificate data source:
data "tls_certificate" "oidc_thumbprint" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

# For the OIDC provider resource:
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc_thumbprint.certificates[0].sha1_fingerprint]
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

# ----------------------------
# IAM Policy for Jenkins to Use EBS CSI Driver
# ----------------------------
data "aws_iam_policy_document" "gp_ebs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }
  }
}

resource "aws_iam_role" "gp_ebs_addon_role" {
  name               = "gp_ebs_addon_role"
  assume_role_policy = data.aws_iam_policy_document.gp_ebs_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "gp_ebs_addon_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.gp_ebs_addon_role.name
}

# ----------------------------
# EBS CSI Driver Addon for Persistent Volume Support
# ----------------------------
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.eks_cluster.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.gp_ebs_addon_role.arn 
  # resolve_conflicts        = "OVERWRITE" # Overwrite existing configurations if any 
  
}

resource "aws_eks_addon" "gp_eks-pod-identity-agent" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "eks-pod-identity-agent"
}
