# resource "random_password" "mysql_user" {
#   length  = 16
#   special = false
# }
# 
# module "mysql_cluster" {
#   source       = "./mysql_cluster"
#   cluster_name = var.mysql_cluster_name
#   network_id   = module.vpc_dev.network_id
#   subnet_id    = module.vpc_dev.subnets[var.default_zone].id
#   zone         = var.default_zone
#   HA           = var.mysql_ha
# }
# 
# module "mysql_db" {
#   source        = "./mysql_db"
#   cluster_id    = module.mysql_cluster.cluster_id
#   db_name       = var.mysql_db_name
#   user_name     = var.mysql_user_name
#   user_password = random_password.mysql_user.result
# }
