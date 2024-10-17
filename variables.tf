variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
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
  description = "Name tag for resources"
  type        = string
}

variable "bits_size" {
  description = " number of bits (subnet size)"
  type        = number
}

variable "destination_cdr_block" {
  description = "Destination CIDR block for the NAT gateway"
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

variable "app_port" {
  description = "Port on which your application runs"
  type        = number
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
}
