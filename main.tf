module "frontend" {
  depends_on = [module.backend]

  source        = "./modules/app"
  instance_type = var.instance_type
  component     = "frontend"
  env           = var.env
  zone_id       = var.zone_id
  vault_token   = var.vault_token
  subnets       = module.vpc.frontend_subnets
  vpc_id        = module.vpc.vpc_id
  lb_type       = "public"
  lb_needed     = true
  lb_subnets    = module_vpc.public_subnets
  app_port      = 80
}

module "backend" {
  depends_on = [module.mysql]

  source        = "./modules/app"
  instance_type = var.instance_type
  component     = "backend"
  env           = var.env
  zone_id       = var.zone_id
  vault_token   = var.vault_token
  subnets       = module.vpc.backend_subnets
  vpc_id        = module.vpc.vpc_id
  lb_type       = "private"
  lb_needed     = true
  lb_subnets    = module_vpc.backend_subnets
  app_port      = 8080
}

module "mysql" {
  source        = "./modules/app"
  instance_type = var.instance_type
  component     = "mysql"
  env           = var.env
  zone_id       = var.zone_id
  vault_token   = var.vault_token
  subnets       = module.vpc.db_subnets
  vpc_id        = module.vpc.vpc_id
  lb_needed     = false
}

module "vpc" {
  source                 = "./modules/vpc"
  env                    = var.env
  vpc_cidr_block         = var.vpc_cidr_block
  default_vpc_id         = var. default_vpc_id
  default_vpc_cidr       = var.default_vpc_cidr
  default_route_table_id = var.default_route_table_id
  frontend_subnets       = var.frontend_subnets
  backend_subnets        = var.backend_subnets
  db_subnets             = var.db_subnets
  public_subnets         = var.public_subnets
  availability_zones     = var.availability_zones
}
