# creating the efs file system on AWS
resource "aws_efs_file_system" "eks" {
  creation_token = "eks"
performance_mode = "generalPurpose"
throughput_mode="bursting"
encrypted=true
}

# creating an mount target in each subnet (where we deployed our k8s workers)
resource "aws_efs_mount_target" "zone_a" {
  file_system_id = aws_efs_file_system.eks.id
  subnet_id      = aws_subnet.private_subnet_zone1.id
  security_groups = [aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id] # we are using the security group that was created by EKS itself when we provisioned the cluster
}
#the other efs mount target in the 2nd private subnet
resource "aws_efs_mount_target" "zone_b" {
  file_system_id = aws_efs_file_system.eks.id
  subnet_id      = aws_subnet.private_subnet_zone2.id
  security_groups = [aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id] # we are using the security group that was created by EKS itself when we provisioned the cluster
}

# grant the necessary permissions for the efs csi driver to attach the efs volumes to the worker nodes
data "aws_iam_policy_document" "efs_csi_driver" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", " ")}:sub"

      values = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
    }
  }

  principals{
    identifiers=[aws_iam_openid_connect_provider.eks.arn]
    type = "Federated"
  }
}

# creating a role where will attach the trust policy
resource "aws_iam_role" "efs_csi_driver" {
  name   = "${aws_eks_cluster.eks.name}-efs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.efs_csi_driver.json
}

# attaching the trust policy to the IAM role: we are using the only policy that AWS manages for the CSI driver
resource "aws_iam_role_policy_attachment" "efs_csi_driver"{
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
    role. = aws_iam_role.efs_csi_driver.name
}