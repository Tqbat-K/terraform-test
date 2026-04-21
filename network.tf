resource "aws_vpc" "keis_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "keis_test"
  }
}

resource "aws_internet_gateway" "keis_igw" {
  vpc_id = aws_vpc.keis_vpc.id

  tags = {
    Name = "keis_igw"
  }
}

resource "aws_route_table" "keis_rt" {
  vpc_id = aws_vpc.keis_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.keis_igw.id
  }

  tags = {
    Name = "keis_rt"
  }
}

resource "aws_subnet" "keis_subnet_1" {
  vpc_id                  = aws_vpc.keis_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "keis_test1"
  }
}

resource "aws_subnet" "keis_subnet_2" {
  vpc_id                  = aws_vpc.keis_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "keis_test2"
  }
}

resource "aws_route_table_association" "keis_routing1" {
  route_table_id = aws_route_table.keis_rt.id
  subnet_id      = aws_subnet.keis_subnet_1.id
}

resource "aws_route_table_association" "keis_routing2" {
  route_table_id = aws_route_table.keis_rt.id
  subnet_id      = aws_subnet.keis_subnet_2.id
}
