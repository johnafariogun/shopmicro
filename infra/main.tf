module "network" {
  source      = "./modules/network"
  environment = var.environment
  aws_region  = var.aws_region
}

module "compute" {
  source               = "./modules/compute"
  environment          = var.environment
  vpc_id               = module.network.vpc_id
  subnet_id            = module.network.public_subnet_id
  key_name             = var.key_name
  admin_ip             = var.admin_ip
}