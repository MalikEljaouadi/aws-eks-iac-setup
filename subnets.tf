resource "aws_subnet" "private_subnet_zone1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/19"
  availability_zone = local.zone1

  tags = {
    "Name"                                                 = "${local.env}-private-${local.zone1}"
    "kubernetes.io/role/internal-elb"                      = "1"     # special tag used by EKS to create private load balancers(in case we would like to expose our service internally within the vpc)
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned" # Optional: recommended when we would like to provision multiple EKS clusters in a single AWS account
  }
}

resource "aws_subnet" "private_subnet_zone2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/19"
  availability_zone = local.zone2

  tags = {
    "Name"                                                 = "${local.env}-private-${local.zone2}"
    "kubernetes.io/role/internal-elb"                      = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
  }
}

resource "aws_subnet" "public_subnet_zone1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.64.0/19"
  availability_zone       = local.zone1
  map_public_ip_on_launch = true # this is setted to "true" because some services and VMs require public IP addresses

  tags = {
    "Name"                                                 = "${local.env}-public-${local.zone1}"
    "kubernetes.io/role/elb"                               = "1"     # EKS will use this tag to discover subnets to create public load balancers
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned" # this tag is to establich relationship with the EKS cluster
  }
}

resource "aws_subnet" "public_subnet_zone2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.96.0/19"
  availability_zone       = local.zone2
  map_public_ip_on_launch = true

  tags = {
    "Name"                                                 = "${local.env}-public-${local.zone2}"
    "kubernetes.io/role/elb"                               = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
  }
}
