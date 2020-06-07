resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Cluster VPC"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Cluster Internet Gateway"
  }
}

# Public Route Table
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "cluster-public-route-table"
  }
}

# Private Route Table
resource "aws_default_route_table" "private_route" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  route {
    nat_gateway_id = aws_nat_gateway.nat.id
    cidr_block     = "0.0.0.0/0"
  }

  tags = {
    Name = "cluster-private-route-table"
  }
}

resource "aws_route_table" "internet" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Cluster Routing Table"
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_subnet_assoc" {
  route_table_id = aws_route_table.public_route.id
  subnet_id      = aws_subnet.public_subnet.id
  depends_on     = [aws_route_table.public_route, aws_subnet.public_subnet]
}

# Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private_subnet_assoc" {
  route_table_id = aws_default_route_table.private_route.id
  subnet_id      = aws_subnet.private_subnet.id
  depends_on     = [aws_default_route_table.private_route, aws_subnet.private_subnet]
}


resource "aws_eip" "eip" {
  depends_on = [aws_internet_gateway.main]
  vpc        = true
}
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "NAT Gateway"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = element(split(",", var.vpc_cidrs), 0)

  tags = {
    Name = "Cluster Subnet A"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(split(",", var.vpc_cidrs), 1)
  map_public_ip_on_launch = true

  tags = {
    Name = "Cluster Subnet B"
  }
}
