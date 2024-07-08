# we need it to get the aws account number for the iam role later
data "aws_caller_identity" "current" {}

# create an admin role that will have admin privileges in the K8s cluster
resource "aws_iam_role" "eks_admin" {
  name = "${local.env}-${local.eks_name}-eks-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          "AWS" :"arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" # in this way, all the users in that aws account will get access to that role
        }
      },
    ]
  })
}

resource "aws_iam_policy" "eks_admin" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_admin" {
  role       = aws_iam_role.eks_admin.name
  policy_arn = aws_iam_policy.eks_admin.arn
}

# this new iam user will assume the eks iam admin role 'eks_admin' created in the previous steps
resource "aws_iam_user" "manager" {
  name = "manager"
}

resource "aws_iam_policy" "eks_assume_admin" {
  name = "AmazonEKSAssumeAdminPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole"
        ]
        Effect   = "Allow"
        Resource = "${aws_iam_role.eks_admin.arn}"
      },
    ]
  })
}

# we attach the policy 'eks_assume_admin' to the assuming user 'manager'
resource "aws_iam_user_policy_attachment" "manager" {
  user = aws_iam_user.manager.name
  policy_arn = aws_iam_policy.eks_assume_admin.arn
}

# bind the 'manager' IAM user with the rbac group 'my-admin'
resource "aws_eks_access_entry" "manager" {
  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = aws_iam_role.eks_admin.arn
  kubernetes_groups = ["my-admin"]
}
