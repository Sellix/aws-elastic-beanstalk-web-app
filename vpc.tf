resource "aws_vpc" "sellix-web-app-vpc" {
  cidr_block            = var.main_cidr_block
  instance_tenancy      = "default"
  enable_dns_support    = "true"
  enable_dns_hostnames  = "true"
  enable_classiclink    = "false"
  tags = {
    "Name"        = "vpc-main"
    "Project"     = "sellix-web-app"
    "Environment" = "production"
  }
}

resource "aws_subnet" "sellix-web-app-subnet" {
  vpc_id                  = aws_vpc.sellix-web-app-vpc.id
  availability_zone       = "eu-west-1a"
  cidr_block              = var.public_cidr_block
  map_public_ip_on_launch = "true"
  tags = {
    "Name"        = "subnet-public"
    "Project"     = "sellix-web-app"
    "Environment" = "production"
  }
}

resource "aws_internet_gateway" "main-gw" {
  vpc_id  = aws_vpc.sellix-web-app-vpc.id
  tags  = {
    "Name"        = "main-gw"
    "Project"     = "sellix-web-app"
    "Environment" = "production"
  }
}

resource "aws_route_table" "sellix-web-app-main-public" {
  vpc_id  = aws_vpc.sellix-web-app-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-gw.id
  }
  tags  = {
    "Name"        = "main-public"
    "Project"     = "sellix-web-app"
    "Environment" = "production"
  }
}

resource "aws_route" "sellix-web-app-main-public" {
  route_table_id         = aws_route_table.sellix-web-app-main-public.id
  gateway_id             = aws_internet_gateway.main-gw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "main-public" {
  subnet_id       = aws_subnet.sellix-web-app-subnet.id
  route_table_id  = aws_route_table.sellix-web-app-main-public.id
}