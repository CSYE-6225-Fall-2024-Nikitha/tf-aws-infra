variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "bits_size" {
  description = " number of bits (subnet size)"
  type        = number
}

variable "public_subnet_count" {
  description = "Number of public subnets"
  type        = number
}

variable "private_subnet_count" {
  description = "Number of private subnets"
  type        = number
}

variable "name" {
  description = "Name for the VPC and associated resources"
  type        = string
}

variable "destination_cdr_block" {
  description = "Destination CIDR block for the NAT gateway"
  type        = string
}

variable "app_port" {
  description = "Port on which your application runs"
  type        = number
}


variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
}

variable "key_name" {
  description = "The key name for SSH access"
  type        = string
}

variable "volume_size" {
  description = "Size of the root volume in GB"
  type        = number
}

variable "volume_type" {
  description = "Type of volume (e.g., standard, gp2, etc.)"
  type        = string
}

variable "delete_on_termination" {
  description = "Whether the volume should be deleted on instance termination"
  type        = bool
}

variable "dialect" {
  description = "The dialect"
  type        = string
  default     = "postgres"
}

variable "db_port" {
  description = "Port on which your Database runs"
  type        = number
}

variable "db_family" {
  description = "Database family"
  type        = string
}

variable "identifier" {
  description = "Identifier for the database instance"
  type        = string
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "engine" {
  description = "Database engine type"
  type        = string
}

variable "engine_version" {
  description = "Version of the database engine"
  type        = string
}

variable "instance_class" {
  description = "Instance class for the database"
  type        = string
}

variable "username" {
  description = "Username for the database"
  type        = string
}

variable "password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot before deletion"
  type        = bool
}

variable "allocated_storage" {
  description = "The allocated storage size (in GB) for the database"
  type        = number
}

variable "subdomain" {
  description = "The subdomain to use for the Route 53 record"
  type        = string
  default     = "dev" # You can set a default value like 'dev' or 'demo'
}

variable "ami" {
  description = "The ami id"
  type        = string
}

variable "cpu_high" {
  description = "CPU high threshold"
  type        = number
}

variable "cpu_low" {
  description = "CPU low threshold"
  type        = number
}


variable "min_instances" {
  description = "Min number of instances for auto scaling"
  type        = number
}

variable "max_instances" {
  description = "Max number of instances for auto scaling"
  type        = number
}

variable "email_server_api_key" {
  description = "API key for the email server (e.g., Mailgun)"
  type        = string
  sensitive   = true
}

variable "lambda_function_name" {
  description = "The name of the Lambda function"
  type        = string
  default     = "verifyEmail"
}
variable "file_name" {
  description = "The name of the file to be uploaded"
  type        = string
  default     = "function.zip" 
}
