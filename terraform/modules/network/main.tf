# -------------------------------------------
#                      VPC
# -------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc" 
  }
}
# -------------------------------------------
#                Public Subnets
# -------------------------------------------
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${each.key}"
    kubernetes.io/role/elb	 = "1"
  }
}
# -------------------------------------------
#                Private Subnets
# -------------------------------------------
resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az

  tags = {
    Name = "${var.project_name}-${each.key}"
  }
}
# -------------------------------------------
#                Internet Gateway
# -------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}
# -------------------------------------------
#                Public Route table
# -------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}
# -------------------------------------------
#         Public Route table Association
# -------------------------------------------
resource "aws_route_table_association" "public" {
  for_each = var.public_subnets

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}
# -------------------------------------------
#                Elastic IP
# -------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = { Name = "${var.project_name}nat-eip" }
}
# -------------------------------------------
#                Nat Gateway
# -------------------------------------------
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["public-1"].id

  tags          = { Name = "${var.project_name}-gateway" }

  depends_on = [aws_internet_gateway.igw]
}
# -------------------------------------------
#                Private Route table
# -------------------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags   = { 
    Name = "${var.project_name}-private-rt" 
  }
}
# -------------------------------------------
#         Private Route table Association
# -------------------------------------------
resource "aws_route_table_association" "private" {
  for_each =var.private_subnets

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private.id
}