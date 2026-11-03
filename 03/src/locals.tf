locals {
  ssh_public_key = file(var.ssh_public_key_path)

  metadata = {
    serial-port-enable = "1"
    ssh-keys           = "${var.vm_user}:${local.ssh_public_key}"
  }
}
