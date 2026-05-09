# ==============================================================================
# Module: Network
# Purpose: Creates VPC, subnets, IGW, NAT Gateway, and routing infrastructure
# Commit: feat(network): Create VPC with public and private subnets
# ==============================================================================

# ------------------------------------------------------------------------------
# VPC Configuration
# Creates the main Virtual Private Cloud with DNS support enabled
# Commit: feat(network): Provision VPC with DNS hostnames and support
# ------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# ------------------------------------------------------------------------------
# Public Subnet
# Public subnet with auto-assign public IP enabled for Jenkins server
# Commit: feat(network): Create public subnet for internet-facing resources
# ------------------------------------------------------------------------------
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet-1a"
  })
}

# ------------------------------------------------------------------------------
# Private Subnet
# Private subnet for internal resources without direct internet access
# Commit: feat(network): Create private subnet for internal resources
# ------------------------------------------------------------------------------
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 2)
  availability_zone = var.availability_zone

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-subnet-1a"
  })
}

# ------------------------------------------------------------------------------
# Internet Gateway
# Provides internet connectivity for public subnet resources
# Commit: feat(network): Attach internet gateway to VPC
# ------------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

# ------------------------------------------------------------------------------
# NAT Gateway EIP
# Elastic IP allocated for NAT Gateway to enable outbound internet access
# Commit: feat(network): Allocate EIP for NAT Gateway
# ------------------------------------------------------------------------------
resource "aws_eip" "nat_gateway" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  })
}

# ------------------------------------------------------------------------------
# NAT Gateway
# Enables private subnet instances to access the internet while blocking inbound
# Commit: feat(network): Deploy NAT Gateway for private subnet outbound access
# ------------------------------------------------------------------------------
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public_1a.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nat-gw"
  })
}

# ------------------------------------------------------------------------------
# Public Route Table
# Routes traffic from public subnet to Internet Gateway
# Commit: feat(network): Configure public route table with IGW route
# ------------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

# ------------------------------------------------------------------------------
# Private Route Table
# Routes traffic from private subnet to NAT Gateway
# Commit: feat(network): Configure private route table with NAT route
# ------------------------------------------------------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-rt"
  })
}

# ------------------------------------------------------------------------------
# Route Table Associations
# Associates subnets with their respective route tables
# Commit: feat(network): Associate subnets with route tables
# ------------------------------------------------------------------------------
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}