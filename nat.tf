# NAT Gateway is used to translate virtual machine IP addresses into public ones to provide internet access to private subnets

resource "aws_eip" "nat" { # before creating the NAT, we will allocate a static IP addresse manually, that would be used later in the NAT gateway
  domain = "vpc"

  tags = {
    Name = "${local.env}-nat"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_zone1.id

  tags = {
    Name = "${local.env}-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}