module "vpc" {
  source   = "../../src/vpc"
  env_name = var.vpc_name
  subnets = [
    { zone = var.default_zone, cidr = var.vpc_cidr },
  ]
}
