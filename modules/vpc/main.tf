
data "aws_availability_zones" "available" {}

locals {
  az_count = length(data.aws_availability_zones.available.names)

  public_subnet_count  = local.az_count >= 3 ? 3 : local.az_count
  private_subnet_count = local.az_count >= 3 ? 3 : local.az_count
}


resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.name
  }
}

resource "aws_subnet" "public_subnet" {
  count             = local.public_subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.bits_size, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnet" {
  count             = local.private_subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.bits_size, count.index + var.public_subnet_count) # Adjust as needed
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "${var.name}-private-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-igw"
  }
}

# Create a public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-public-rt"
  }
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public_subnets" {
  count          = local.public_subnet_count
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create a public route to the Internet Gateway
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = var.destination_cdr_block
  gateway_id             = aws_internet_gateway.main.id
}

# Create a private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-private-rt"
  }
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private_subnets" {
  count          = local.private_subnet_count
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private.id
}
