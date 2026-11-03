resource "yandex_compute_instance" "web" {
  count       = var.web_vm.vm_count
  name        = "${var.web_vm.name_prefix}-${count.index + 1}"
  platform_id = var.vm_platform_id

  resources {
    cores         = var.web_vm.cpu
    memory        = var.web_vm.ram
    core_fraction = var.vm_core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = var.web_vm.disk_volume
    }
  }

  scheduling_policy {
    preemptible = var.vm_preemptible
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop.id
    nat                = var.vm_nat
    security_group_ids = [yandex_vpc_security_group.example.id]
  }

  metadata = local.metadata

  depends_on = [yandex_compute_instance.db]
}
