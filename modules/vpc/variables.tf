variable "vpc_cidr" {
  description = "CIDR block for the VPC"
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

# Variable for application port
variable "app_port" {
  description = "Port on which your application runs"
  type        = number
  default     = 8080 # Update this to the port your app runs on
}


# Variable for instance type
variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
  default     = "t2.micro"
}

# Variable for SSH key pair name
variable "key_name" {
  description = "The key name for SSH access"
  type        = string
}
