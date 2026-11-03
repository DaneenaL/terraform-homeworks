module "vpc_dev" {
  source   = "./vpc"
  env_name = var.vpc_name
  subnets = [
    { zone = var.default_zone, cidr = var.default_cidr[0] },
  ]
}

module "vpc_prod" {
  source   = "./vpc"
  env_name = var.vpc_prod_name
  subnets  = var.prod_subnets
}
