# install the generic store csi driver that would integrate secrets with the cloud provider.
# since we are dealing with CSI (container storage interface), then the secrets will be mounted as k8s volumes
resource "helm_release" "secrets_csi_driver" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace = "kube-system"
  version    = "1.4.3"
  
  # explicitly enable the env var in the helm chart, so we can use the secrets as env vars and inside the container 
  set {
    name  = "syncSecret.enabled"
    value = "true"
  }

  depends_on = [helm_release.efs_csi_driver]
}

# installing the cloud specific provider
resource "helm_release" "secrets_csi_driver_aws_provider" {
  name       = "secrets-store-csi-driver-aws-provider"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace = "kube-system"
  version    = "0.3.8"
  
  depends_on = [helm_release.secrets_csi_driver]
}

# since eks pod identities are still new (not supported by all the k8s extensions), we use openid connect
# craeting a trust policy: it's not used by the csi driver itself, but it's used by the app that needs access to a specific secret
data "aws_iam_policy_document" "myapp_secrets" {
  statement {

    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect = "Allow"

    condition{
        test = "StringEquals"
        variable = "${replace(aws_iam_openid_connect_provider.eks.url, "hhtps://", "")}:sub"
        values = ["system:serviceaccount:12-example:myapp"] # specifying the k8s service account(myapp) and the namespace where it will be deployed (12-example)
    }
    principals{
        identifiers = [aws_iam_openid_connect_provider.eks.arn]
        type = "Federated"
    }
  }

}

# creating a role
resource "aws_iam_role" "myapp_secrets"{
    name= "${aws_eks_cluster.eks.name}-myapp-secrets"
    assume_role_policy = data.aws_iam_policy_document.myapp_secrets.json
}

# creating a policy that will grant access for this application to a specific secret in aws
resource "aws_iam_policy" "myapp_secrets" {
  name   = "${aws_eks_cluster.eks.name}-myapp-secrets"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action=[
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
            ]
            Resource = "*" # here we are allowing access to all the secrets instead of specifying the arn of the target secrets
        }
    ]
  })
}

# attaching the policy to the created role
resource "aws_iam_role_policy_attachment" "myapp_secrets"{
    policy_arn = aws_iam_policy.myapp_secrets.arn
    role = aws_iam_role = aws_iam_role.myapp_secrets.name
}

# we need the role arn to link AWS IAM to the k8s service account
output "myapp_secrets_role_arn" {
  value       = aws_iam_role.myapp_secrets.arn
}
