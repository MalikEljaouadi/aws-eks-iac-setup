# load balancer controllers are used to create load balancers and ingresses

#### IAM permission setting for the Load Balancer Controller ####

# for this load balancer controller, we need to grant it access to access to AWS so he can be capable to create load balancers
data "aws_iam_policy_document" "aws_lbc" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"] # To grant access, we use pod identities 
    }

    actions = [
        "sts:AssumeRole",
        "sts:TagSession"
        ]
  }
}

# creating the iam role that will be used by this controller
resource "aws_iam_role" "aws_lbc" {
  name               = "${aws_eks_cluster.eks.name}-aws-lbc"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc.json
}

# creating the policy
resource "aws_iam_policy" "aws_lbc" {
  name        = "AWSLoadBalancerController"
  policy = file("./iam/AWSLoadBalancerController.json")
}

# attaching the policy to this role 
resource "aws_iam_role_policy_attachment" "aws_lbc" {
  role       = aws_iam_role.aws_lbc.name
  policy_arn = aws_iam_policy.aws_lbc.arn
}

# finally, we need to link this iam role with the kubernetes service account
resource "aws_eks_pod_identity_association" "aws_lbc" {
  cluster_name    = aws_eks_cluster.eks.name
  namespace       = "kube-system" # this lb-controller should be deployed in the kube-system namespace
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_lbc.arn
}

#### Deploy the Load Balancer controller using Helm ####
resource "helm_release" "aws_lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace = "kube-system"
  version    = "1.7.2"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.eks.name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  depends_on = [helm_release.cluster_autoscaler]
}