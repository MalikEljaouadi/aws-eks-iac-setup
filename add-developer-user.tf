# create a developer IAW user in AWS
resource "aws_iam_user" "developer" {
  name = "developer"
}

# grant access to eks to be able to update the local k8s config and connect to the cluster
resource "aws_iam_policy" "developer_eks" {
  name = "AmazonEKSDeveloperPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# attach the following policy to the previously defined user
resource "aws_iam_user_policy_attachment" "developer_eks" {
  user       = aws_iam_user.developer.name
  policy_arn = aws_iam_policy.developer_eks.arn
}

# bind the 'developer' IAM user with the rbac 'my-viewer'
resource "aws_eks_access_entry" "developer" {
  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = aws_iam_user.developer.arn
  kubernetes_groups = ["my-viewer"]
}