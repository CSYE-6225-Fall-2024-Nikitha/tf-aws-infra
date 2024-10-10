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

variable "bits_size" {
  description = " number of bits (subnet size)"
  type        = number
}