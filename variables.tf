variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1" 
}

variable "vpc_count" {
  description = "Number of VPCs to create"
  type        = number
  default     = 1  
}

variable "vpc_cidrs" {
  description = "List of CIDR blocks for VPCs"
  type        = list(string)
  default     = ["10.0.0.0/16"]  # Single VPC CIDR block
}

variable "subnet_cidrs" {
  description = "List of CIDR blocks for public and private subnets"
  type        = list(string)
  default     = [
    "10.0.1.0/24",  # Public subnet 1
    "10.0.2.0/24",  # Public subnet 2
    "10.0.3.0/24",  # Public subnet 3
    "10.0.4.0/24",  # Private subnet 1
    "10.0.5.0/24",  # Private subnet 2
    "10.0.6.0/24"   # Private subnet 3
  ]
}

variable "vpc_name" {
  description = "Base name for the VPC and related resources"
  type        = string
  default     = "csye-6225"  
}
