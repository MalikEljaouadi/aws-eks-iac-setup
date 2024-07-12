# creating a trust policy since we are using EKS pod identities to grant the necessary permissions
data "aws_iam_policy_document" "ebs_csi_driver" {
  statement {
    effect = "Allow"

    principals = {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]

  }

}

# creating the IAM role using the policy
resource "aws_iam_role" "ebs_csi_driver" {
  name               = "instance_role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver.json
}

# attaching the policy to the IAM role
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy" # this is an AWS-managed EBSCSIDriverPolicy: it will allocate EBS volumes and attach them to the worker nodes
}

# encrypting the EBS drivers (Optional but recommended)
resource "aws_iam_policy" "ebs_csi_driver_encryption" {
  name        = "${aws_eks_cluster.eks.name}-ebs-csi-driver-encryption"
  description = "policy for encrypting the EBS volume"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:CreateGrant"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# attching the encryption policy with our role
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_encryption" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = aws_iam_policy.ebs_csi_driver_encryption.arn
}

# associating the role to the k8s service account in kube-system namespace
resource "aws_eks_pod_identity_association" "ebs_csi_driver" {
  cluster_name    = aws_eks_cluster.eks.name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi_driver.arn
}

# finally, to deploy we can use the managed EKS addon (same as a Helm chart just wrapped and tested by AWS)
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.eks.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.30.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
}