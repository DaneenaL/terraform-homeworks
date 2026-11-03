resource "yandex_compute_disk" "storage" {
  count = var.extra_disks.disk_count
  name  = "${var.extra_disks.name_prefix}-${count.index + 1}"
  type  = var.extra_disks.type
  size  = var.extra_disks.size
  zone  = var.default_zone
}

resource "yandex_compute_instance" "storage" {
  name        = var.storage_vm.name
  platform_id = var.vm_platform_id

  resources {
    cores         = var.storage_vm.cpu
    memory        = var.storage_vm.ram
    core_fraction = var.vm_core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = var.storage_vm.disk_volume
    }
  }

  dynamic "secondary_disk" {
    for_each = yandex_compute_disk.storage
    content {
      disk_id = secondary_disk.value.id
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
}
