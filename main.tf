module "vpc" {
  source                = "./modules/vpc"
  vpc_cidr              = var.vpc_cidr
  public_subnet_count   = var.public_subnet_count
  private_subnet_count  = var.private_subnet_count
  name                  = var.name
  bits_size             = var.bits_size
  destination_cdr_block = var.destination_cdr_block
  key_name              = var.key_name
  volume_size           = var.volume_size
  volume_type           = var.volume_type
  delete_on_termination = var.delete_on_termination
  app_port              = var.app_port
  instance_type         = var.instance_type
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "internet_gateway_id" {
  value = module.vpc.internet_gateway_id
}
