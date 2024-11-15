
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

  # ingress {
  #   description = "Allow HTTP"
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    description = "Allow WebApp Port"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    #cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  # ingress {
  #   description = "Allow HTTPS"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

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
# resource "aws_instance" "app_instance" {
#   ami                         = var.ami
#   instance_type               = var.instance_type
#   availability_zone           = element(data.aws_availability_zones.available.names, 0)
#   subnet_id                   = aws_subnet.public_subnet[0].id
#   security_groups             = [aws_security_group.application_security_group.id]
#   key_name                    = var.key_name
#   disable_api_termination     = false
#   associate_public_ip_address = true
#   iam_instance_profile        = aws_iam_instance_profile.combined_instance_profile.name
#   user_data = templatefile("${path.module}/userData.tpl", {
#     DB_NAME      = aws_db_instance.rds_instance.db_name
#     DB_USER      = aws_db_instance.rds_instance.username
#     DB_PASSWORD  = aws_db_instance.rds_instance.password
#     DB_HOST      = aws_db_instance.rds_instance.address
#     DB_PORT      = var.db_port
#     DB_DIALECT   = var.dialect
#     S3_BUCKET_ID = aws_s3_bucket.csye6225_bucket.bucket
#     AWS_REGION   = var.region
#   })

#   root_block_device {
#     volume_size           = var.volume_size
#     volume_type           = var.volume_type
#     delete_on_termination = var.delete_on_termination
#   }

#   tags = {
#     Name = "${var.name}-app-instance"
#   }
# }

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


resource "aws_route53_record" "app_record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.subdomain}.nikitha-kambhampati.me"
  type    = "A"

  alias {
    name                   = aws_lb.web_app_lb.dns_name
    zone_id                = aws_lb.web_app_lb.zone_id
    evaluate_target_health = true
  }

}



# IAM Role for combined access
resource "aws_iam_role" "combined_role" {
  name = "ec2_combined_role"

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


#IAM Policy for Cloud watch agent and s3
# That is this EC2 can write logs and metrics to the Cloudwatch
resource "aws_iam_policy" "combined_policy" {
  name        = "combined_cloudwatch_s3_policy"
  description = "Combined policy for CloudWatch agent and S3 access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DeleteTargetGroup",
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "sns:Publish",
          "sns:Subscribe",
          "*"
        ],
        Resource = [
          "${aws_s3_bucket.csye6225_bucket.arn}/*", # Allows actions on all objects in your specified S3 bucket
          aws_s3_bucket.csye6225_bucket.arn,
          "*",
          "arn:aws:cloudwatch:${var.region}::dashboard/*",

          "arn:aws:cloudwatch:${var.region}::metric/*",

          "arn:aws:logs:${var.region}::log-group:*",
          "arn:aws:logs:${var.region}::log-group:*:log-stream:*",
          "${aws_sns_topic.user_verifications.arn}/*"

        ]
      }
    ]
  })
}

# Attach this policy to the IAM role# Attach the combined policy to the IAM role
resource "aws_iam_role_policy_attachment" "attach_combined_policy" {
  role       = aws_iam_role.combined_role.name
  policy_arn = aws_iam_policy.combined_policy.arn
}

# EC2 Instance Profile for the combined role
resource "aws_iam_instance_profile" "combined_instance_profile" {
  name = "combined_instance_profile"
  role = aws_iam_role.combined_role.name
}

// Load Balancer Security Group
resource "aws_security_group" "load_balancer_security_group" {
  name        = "load_balancer_security_group"
  description = "Security group for load balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}



// Auto scaling and Launch Template
resource "aws_launch_template" "web_app_launch_template" {
  name                    = "csye6225_launch_template"
  image_id                = var.ami
  instance_type           = var.instance_type
  key_name                = var.key_name
  disable_api_termination = false
  network_interfaces {
    associate_public_ip_address = true
    #subnet_id                   = aws_subnet.public_subnet[*].id
    device_index = 0
    security_groups = [
      aws_security_group.application_security_group.id
    ]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.combined_instance_profile.name
  }
  lifecycle {
    prevent_destroy = false
  }

  user_data = base64encode(templatefile("${path.module}/userData.tpl", {
    DB_NAME       = aws_db_instance.rds_instance.db_name
    DB_USER       = aws_db_instance.rds_instance.username
    DB_PASSWORD   = aws_db_instance.rds_instance.password
    DB_HOST       = aws_db_instance.rds_instance.address
    DB_PORT       = var.db_port
    DB_DIALECT    = var.dialect
    S3_BUCKET_ID  = aws_s3_bucket.csye6225_bucket.bucket
    AWS_REGION    = var.region
    SNS_TOPIC_ARN = aws_sns_topic.user_verifications.arn
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.name}-app-instance"
    }
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.volume_size
      volume_type           = var.volume_type
      delete_on_termination = var.delete_on_termination
    }
  }
}


resource "aws_autoscaling_group" "webapp_autoscaling_group" {
  name              = "csye6225_asg"
  target_group_arns = [aws_lb_target_group.web_app_target_group.arn]
  launch_template {
    name    = aws_launch_template.web_app_launch_template.name
    version = "$Latest"
  }

  min_size            = var.min_instances
  max_size            = var.max_instances
  desired_capacity    = var.min_instances
  vpc_zone_identifier = [aws_subnet.public_subnet[*].id]
  default_cooldown    = 60

  tag {
    key                 = "AutoScalingGroup"
    value               = "WebAppAutoScalingGroup"
    propagate_at_launch = true
  }
}

#Auto scaling policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.webapp_autoscaling_group.name

}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale_down"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.webapp_autoscaling_group.name

}

# Create CloudWatch alarms for the scaling policies
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "high_cpu_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_high
  alarm_description   = "Alarm when CPU exceeds ${var.cpu_high}%"
  actions_enabled     = true
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_autoscaling_group.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "low_cpu_alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_low
  actions_enabled     = true
  alarm_description   = "Alarm when CPU is below threshold ${var.cpu_low}%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_autoscaling_group.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}

# create app load balancer
resource "aws_lb" "web_app_lb" {
  name               = "web-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_security_group.id]
  # subnets                    = aws_subnet.public_subnet[*].id
  subnets                    = [aws_subnet.public_subnet[0].id, aws_subnet.public_subnet[1].id, aws_subnet.public_subnet[2].id]
  enable_deletion_protection = false
  tags = {
    Name = "web_app_load_balancer"
  }
}

resource "aws_lb_target_group" "web_app_target_group" {
  name     = "web-app-target-group"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 5
    interval            = 100
    port                = "8080"
    protocol            = "HTTP"
    unhealthy_threshold = 5
    path                = "/healthz"
    timeout             = 10
    matcher             = "200"
  }

  tags = {
    Name = "web_app_target_group"
  }
}


resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.web_app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_app_target_group.arn
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.webapp_autoscaling_group.name
  lb_target_group_arn    = aws_lb_target_group.web_app_target_group.arn
}

#SNS  Topic
resource "aws_sns_topic" "user_verifications" {
  name = "user-verification-topic"
}


resource "aws_iam_role" "lambda_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "lambda_s3_access_policy"
  description = "IAM policy for Lambda to access SNS and RDS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
          "rds:DescribeDBInstances",
          "rds:ExecuteStatement"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}


resource "aws_lambda_function" "email_verification_function" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.verifyEmail"
  runtime       = "nodejs14.x"

  filename = "/Users/nikithakambhampati/Desktop/a-08/serverless/lambda.zip"

  environment {
    variables = {
      DB_NAME         = aws_db_instance.rds_instance.db_name
      DB_USER         = aws_db_instance.rds_instance.username
      DB_PASSWORD     = aws_db_instance.rds_instance.password
      DB_HOST         = aws_db_instance.rds_instance.address
      DB_PORT         = var.db_port
      DB_DIALECT      = var.dialect
      MAILGUN_API_KEY = var.email_server_api_key
      MAILGUN_DOMAIN  = "${var.subdomain}.nikitha-kambhampati.me"
    }
  }
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  principal     = "sns.amazonaws.com"
  function_name = aws_lambda_function.email_verification_function.function_name
  source_arn    = aws_sns_topic.user_verifications.arn
}
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.user_verifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.email_verification_function.arn
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}