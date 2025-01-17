# extracting the tls certificate from the cluster
data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

# use the extracted tls certificate to create an OpenID connect provider on AWS side
resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.eks.certificates[0].sha1_fingerprint]
}