data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = var.vpc_state_path
  }
}

data "template_file" "cloudinit" {
  template = file("${path.module}/cloud-init.yml")
  vars = {
    vm_user        = var.vm_user
    ssh_public_key = file(var.vm_ssh_public_key_path)
  }
}

module "vm" {
  source         = "git::https://github.com/udjin10/yandex_compute_instance.git?ref=main"
  env_name       = var.vm_env_name
  network_id     = data.terraform_remote_state.vpc.outputs.network_id
  subnet_zones   = [var.default_zone]
  subnet_ids     = [data.terraform_remote_state.vpc.outputs.subnet_id]
  instance_name  = var.vm_name
  instance_count = 1
  image_family   = var.vm_image_family
  platform       = var.vm_platform_id
  public_ip      = var.vm_public_ip

  instance_core_fraction = var.vm_core_fraction
  preemptible            = var.vm_preemptible

  labels = {
    project = var.vm_name
  }

  metadata = {
    user-data          = data.template_file.cloudinit.rendered
    serial-port-enable = 1
  }
}
