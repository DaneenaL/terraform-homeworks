locals {
  vm_web_name = "${var.vm_project}-${var.vpc_name}-${var.vm_platform_name}-web"
  vm_db_name  = "${var.vm_project}-${var.vpc_name}-${var.vm_platform_name}-db"
}
