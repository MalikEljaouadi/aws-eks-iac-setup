# private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"            # cidr block that indicate the default route: if no other route match the request, this route will be used by the request (the destination IP addresse)
    nat_gateway_id = aws_nat_gateway.nat.id # in this case, if the application wants to send a request to an IP address wich is not within the VPC range, it will be routes outside of the VPC using the NAT gateway
  }

  tags = {
    Name = "${local.env}-private"
  }
}

# public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id # we are using the internet gateway as a default route
  }

  tags = {
    Name = "${local.env}-private"
  }
}

# finally, we associate the route table with the 4 subnets
resource "aws_route_table_association" "private_zone1" {
  subnet_id      = aws_subnet.private_subnet_zone1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_zone2" {
  subnet_id      = aws_subnet.private_subnet_zone2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public_zone1" {
  subnet_id      = aws_subnet.public_subnet_zone1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_zone2" {
  subnet_id      = aws_subnet.public_subnet_zone2.id
  route_table_id = aws_route_table.public.id
}
