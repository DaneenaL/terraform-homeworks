
data "template_file" "cloudinit" {
  template = file("${path.module}/cloud-init.yml")
  vars = {
    vm_user        = var.vm_user
    ssh_public_key = file(var.vm_ssh_public_key_path)
  }
}

module "marketing_vm" {
  source                 = "git::https://github.com/udjin10/yandex_compute_instance.git?ref=main"
  env_name               = var.vm_env_name
  network_id             = module.vpc_dev.network_id
  subnet_zones           = [var.default_zone]
  subnet_ids             = [module.vpc_dev.subnets[var.default_zone].id]
  instance_name          = var.projects.marketing
  instance_count         = var.vm_instance_count
  image_family           = var.vm_image_family
  public_ip              = var.vm_public_ip
  platform               = var.vm_platform_id
  instance_core_fraction = var.vm_core_fraction
  preemptible            = var.vm_preemptible

  labels = {
    owner   = var.vm_owner
    project = var.projects.marketing
  }

  metadata = {
    user-data          = data.template_file.cloudinit.rendered
    serial-port-enable = 1
  }
}

module "analytics_vm" {
  source                 = "git::https://github.com/udjin10/yandex_compute_instance.git?ref=main"
  env_name               = var.vm_env_name
  network_id             = module.vpc_dev.network_id
  subnet_zones           = [var.default_zone]
  subnet_ids             = [module.vpc_dev.subnets[var.default_zone].id]
  instance_name          = var.projects.analytics
  instance_count         = var.vm_instance_count
  image_family           = var.vm_image_family
  public_ip              = var.vm_public_ip
  platform               = var.vm_platform_id
  instance_core_fraction = var.vm_core_fraction
  preemptible            = var.vm_preemptible

  labels = {
    owner   = var.vm_owner
    project = var.projects.analytics
  }

  metadata = {
    user-data          = data.template_file.cloudinit.rendered
    serial-port-enable = 1
  }
}
