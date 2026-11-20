# CloudForge Virtual Private Cloud
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "cloudforge-vpc"
  })
}

# First subnet
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "cloudforge-public-a"
  })
}

# Second subnet
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "cloudforge-public-b"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "cloudforge-igw"
  })
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "cloudforge-public-rt"
  })
}

# Associate Subnet A with Public Route Table
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# Associate Subnet B with Public Route Table
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Security group for CareerFlow API
resource "aws_security_group" "ecs_api" {
  name        = "cloudforge-ecs-api-sg"
  description = "Security group for CareerFlow API containers"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "cloudforge-ecs-api-sg"
  })
}

# Allow inbound HTTP traffic to FastAPI
resource "aws_vpc_security_group_ingress_rule" "ecs_api_http" {
  security_group_id = aws_security_group.ecs_api.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 8000
  to_port     = 8000
  ip_protocol = "tcp"

  description = "Allow HTTP traffic to CareerFlow API"
}

# Allow outbound traffic
resource "aws_vpc_security_group_egress_rule" "ecs_api_outbound" {
  security_group_id = aws_security_group.ecs_api.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow outbound traffic from ECS containers"
}