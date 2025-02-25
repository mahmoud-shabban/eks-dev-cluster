# create vpc, subnets route tables

resource "aws_vpc" "eks_vpc" {
  cidr_block         = "10.0.0.0/16"
  instance_tenancy   = "default"
  enable_dns_support = true


  tags = {
    Name = "dev-eks-vpc"
  }
}


# public and private subnets
resource "aws_subnet" "subnets" {
  vpc_id                  = aws_vpc.eks_vpc.id
  for_each                = var.subnets
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = {
    Name = each.key
    "kubernetes.io/role/elb" = strcontains(each.key, "public") ? 1 : 0
    "kubernetes.io/cluster/${var.cluster-name}" = var.cluster-name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id

}

resource "aws_eip" "nat-eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat-gw" {
  subnet_id     = aws_subnet.subnets["public-sub-1"].id
  allocation_id = aws_eip.nat-eip.allocation_id
}


resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }


  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }


  tags = {
    Name = "private-route-table"
  }
}



resource "aws_route_table_association" "public-rt-association" {
  for_each       = toset(["public-sub-1", "public-sub-2"])
  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "private-rt-association" {
  for_each       = toset(["private-sub-1", "private-sub-2"])
  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.private-rt.id
}