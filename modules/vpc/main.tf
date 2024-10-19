
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

data "aws_ami" "latest_custom_ami" {
  # owners = ["self"]

  filter {
    name   = "name"
    values = ["my-custom-ami-*"]
  }

  most_recent = true
}

# Application Security Group
resource "aws_security_group" "application_security_group" {
  name        = "application_security_group"
  description = "Security group for EC2 instances hosting web applications"
  vpc_id      = aws_vpc.main.id

  # Ingress rules (allow traffic on ports 22, 80, 443, and a custom app port)
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow WebApp Port"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule (allow all outgoing traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "application_security_group"
  }
}

# EC2 Instance
resource "aws_instance" "app_instance" {
  ami                         = data.aws_ami.latest_custom_ami.id
  instance_type               = var.instance_type
  availability_zone           = element(data.aws_availability_zones.available.names, 0)
  subnet_id                   = aws_subnet.public_subnet[0].id
  security_groups             = [aws_security_group.application_security_group.id]
  key_name                    = var.key_name
  disable_api_termination     = false
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.volume_size
    volume_type           = var.volume_type
    delete_on_termination = var.delete_on_termination
  }

  tags = {
    Name = "${var.name}-app-instance"
  }
}


# Security group for RDS database instance - PostgreSQL
resource "aws_security_group" "database_security_group" {
  name        = "database_security_group"
  description = "Security group for database security"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow TCP traffic on PostgreSQL port"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.application_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "database_security_group"
  }
}

# RDS Parameter Group
resource "aws_db_parameter_group" "rds_parameter_group" {
  name   = "rds_parameter_group"
  family = "postgres14"
}

resource "aws_db_subnet_group" "private_subnet_group" {
  name       = "private-subnet-group"
  subnet_ids = aws_subnet.private_subnet[*].id

  tags = {
    Name = "Private Subnet Group for RDS"
  }
}


resource "aws_db_instance" "rds_instance" {
  identifier             = "csye6225"
  db_name                = "csye6225"
  engine                 = "postgres"
  engine_version         = "14"
  instance_class         = "db.t3.micro"
  username               = "csye6225"
  password               = "123456"
  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.private_subnet_group.name
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.database_security_group.id]
  tags = {
    Name = "rds_instance"
  }
}