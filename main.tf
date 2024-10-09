terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Region
provider "aws" {
  region = var.aws_region 
  profile = "sk"
}

# Create a VPC
resource "aws_vpc" "main" {
  count      = var.vpc_count
  cidr_block = var.vpc_cidrs[count.index]  # Use count.index to get the correct CIDR from the list

  tags = {
    Name = "${var.vpc_name}-${count.index + 1}"
  }
}

resource "aws_subnet" "public" {
  count = 3  
  vpc_id = aws_vpc.main[count.index % var.vpc_count].id  
  cidr_block = element(var.subnet_cidrs, count.index)  
  availability_zone = element(data.aws_availability_zones.available.names, count.index % 3)  

  map_public_ip_on_launch = true  

  tags = {
    Name = "${var.vpc_name}-public-${count.index + 1}"  
  }
}

resource "aws_subnet" "private" {
  count = 3  
  vpc_id = aws_vpc.main[count.index % var.vpc_count].id  
  cidr_block = element(var.subnet_cidrs, count.index + 3)  
  availability_zone = element(data.aws_availability_zones.available.names, count.index % 3)  

  tags = {
    Name = "${var.vpc_name}-private-${count.index + 1}"  
  }
}

data "aws_availability_zones" "available" {}  

resource "aws_internet_gateway" "igw" {
  count = var.vpc_count  
  vpc_id = aws_vpc.main[count.index].id  

  tags = {
    Name = "${var.vpc_name}-${count.index + 1}-igw"  #
  }
}

resource "aws_route_table" "public" {
  count = var.vpc_count  
  vpc_id = aws_vpc.main[count.index].id  

  route {
    cidr_block = "0.0.0.0/0"  
    gateway_id = aws_internet_gateway.igw[count.index].id  
  }

  tags = {
    Name = "${var.vpc_name}-${count.index + 1}-public-rt" 
  }
}

resource "aws_route_table" "private" {
  count = var.vpc_count  
  vpc_id = aws_vpc.main[count.index].id  
  tags = {
    Name = "${var.vpc_name}-${count.index + 1}-private-rt"  
  }
}

resource "aws_route_table_association" "public_association" {
  count          = 3  # Assuming you want to associate 3 public subnets
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id  # Reference the first (and only) public route table
}

resource "aws_route_table_association" "private_association" {
  count          = 3  # Assuming you want to associate 3 private subnets
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id  # Reference the first (and only) private route table
}
