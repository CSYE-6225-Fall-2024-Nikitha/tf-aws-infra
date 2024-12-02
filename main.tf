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
  db_port               = var.db_port
  db_family             = var.db_family
  instance_type         = var.instance_type
  dialect               = var.dialect
  db_name               = var.db_name
  engine                = var.engine
  engine_version        = var.engine_version
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  username              = var.username
  password              = var.password
  multi_az              = var.multi_az
  identifier            = var.identifier
  skip_final_snapshot   = var.skip_final_snapshot
  subdomain             = var.subdomain
  ami                   = var.ami
  region                = var.region
  cpu_high              = var.cpu_high
  cpu_low               = var.cpu_low
  min_instances         = var.min_instances
  max_instances         = var.max_instances
  email_server_api_key_dev  = var.email_server_api_key_dev
  email_server_api_key_demo = var.email_server_api_key_demo
  file_name             = var.file_name
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
