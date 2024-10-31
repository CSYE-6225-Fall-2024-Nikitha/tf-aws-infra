
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

# data "aws_ami" "latest_custom_ami" {
#   owners = ["self"]

#   filter {
#     name   = "name"
#     values = ["my-custom-ami-*"]
#   }

#   most_recent = true
# }

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


# Security group for RDS database instance - PostgreSQL
resource "aws_security_group" "database_security_group" {
  name        = "database_security_group"
  description = "Security group for database security"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow TCP traffic on PostgreSQL port"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.application_security_group.id]
  }


  tags = {
    Name = "database_security_group"
  }
}

# RDS Parameter Group
resource "aws_db_parameter_group" "rds_parameter_group" {
  name   = "rds-parameter-group"
  family = var.db_family
}

resource "aws_db_subnet_group" "private_subnet_group" {
  name       = "private-subnet-group"
  subnet_ids = aws_subnet.private_subnet[*].id

  tags = {
    Name = "Private Subnet Group for RDS"
  }
}


resource "aws_db_instance" "rds_instance" {
  identifier             = var.identifier
  db_name                = var.db_name
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  username               = var.username
  password               = var.password
  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.private_subnet_group.name
  publicly_accessible    = false
  parameter_group_name   = aws_db_parameter_group.rds_parameter_group.name
  vpc_security_group_ids = [aws_security_group.database_security_group.id]
  allocated_storage      = var.allocated_storage
  skip_final_snapshot    = var.skip_final_snapshot
  tags = {
    Name = "rds_instance"
  }
}

# EC2 Instance
resource "aws_instance" "app_instance" {
  ami                         = "ami-038c10b41162a0e48"
  instance_type               = var.instance_type
  availability_zone           = element(data.aws_availability_zones.available.names, 0)
  subnet_id                   = aws_subnet.public_subnet[0].id
  security_groups             = [aws_security_group.application_security_group.id]
  key_name                    = var.key_name
  disable_api_termination     = false
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.combined_instance_profile.name
  user_data = templatefile("${path.module}/userData.tpl", {
    DB_NAME     = aws_db_instance.rds_instance.db_name
    DB_USER     = aws_db_instance.rds_instance.username
    DB_PASSWORD = aws_db_instance.rds_instance.password
    DB_HOST     = aws_db_instance.rds_instance.address
    DB_PORT     = var.db_port
    DB_DIALECT  = var.dialect
    S3_BUCKET_ID= aws_s3_bucket.csye6225_bucket.bucket
  })

  root_block_device {
    volume_size           = var.volume_size
    volume_type           = var.volume_type
    delete_on_termination = var.delete_on_termination
  }

  tags = {
    Name = "${var.name}-app-instance"
  }
}

# S3 bucket
resource "aws_s3_bucket" "csye6225_bucket" {
  bucket        = "bucket-${uuid()}"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "my_bucket_encryption" {
  bucket = aws_s3_bucket.csye6225_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "my_bucket_lifecycle" {
  bucket = aws_s3_bucket.csye6225_bucket.id

  rule {
    id     = "TransitionToIA"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

data "aws_route53_zone" "selected" {
  name = "${var.subdomain}.nikitha-kambhampati.me"
}


data "aws_route53_zone" "main" {
  name = "nikitha-kambhampati.me"
}

resource "aws_route53_record" "app_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.subdomain}.nikitha-kambhampati.me"
  type    = "A"

  ttl     = 300
  records = [aws_instance.app_instance.public_ip]
}


#IAM Role for Cloud watch agent
# like Role = Permission
#EC2 has permission to send logs to cloud watch
# With the help of this role, logs can be sent to Cloudwatch from EC2
resource "aws_iam_role" "cloudwatch_agent_role" {
  name = "ec2_cloudwatch_agent_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}


#IAM Policy for Cloud watch agent
# That is this EC2 can write logs and metrics to the Cloudwatch
resource "aws_iam_policy" "cloudwatch_agent_policy" {
  name        = "cloudwatch_agent_policy"
  description = "Policy for CloudWatch agent to write logs and metrics"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Attach this policy to the IAM role
resource "aws_iam_role_policy_attachment" "attach_cloudwatch_policy" {
  role       = aws_iam_role.cloudwatch_agent_role.name
  policy_arn = aws_iam_policy.cloudwatch_agent_policy.arn
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "cloudwatch_instance_profile" {
  name = "cloudwatch_instance_profile"
  role = aws_iam_role.cloudwatch_agent_role.name
}

# IAM Role for S3 Access
resource "aws_iam_role" "s3_access_role" {
  name = "ec2_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for S3 Access
resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3_access_policy"
  description = "Policy for EC2 instances to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.csye6225_bucket.arn}/*",  
          aws_s3_bucket.csye6225_bucket.arn            
        ]
      }
    ]
  })
}

# Attach the S3 policy to the IAM role
resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.s3_access_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Attach the S3 access role to the EC2 Instance
resource "aws_iam_instance_profile" "s3_instance_profile" {
  name = "s3_instance_profile"
  role = aws_iam_role.s3_access_role.name
}

# Step 1: Create a new IAM role
resource "aws_iam_role" "combined_role" {
  name               = "combined_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# Step 2: Attach existing policies to the new role
resource "aws_iam_role_policy_attachment" "s3_access" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role       = aws_iam_role.combined_role.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_access" {
  policy_arn = aws_iam_policy.cloudwatch_access_policy.arn
  role       = aws_iam_role.combined_role.name
}

# Step 3: Create a new instance profile for the combined role
resource "aws_iam_instance_profile" "combined_instance_profile" {
  name = "combined_instance_profile"
  role = aws_iam_role.combined_role.name
}

