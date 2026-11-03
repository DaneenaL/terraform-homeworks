resource "yandex_mdb_mysql_cluster" "this" {
  name                = var.cluster_name
  environment         = var.environment
  network_id          = var.network_id
  version             = var.mysql_version
  deletion_protection = false

  resources {
    resource_preset_id = var.resource_preset_id
    disk_type_id       = var.disk_type_id
    disk_size          = var.disk_size
  }

  dynamic "host" {
    for_each = range(var.HA ? var.ha_hosts_count : 1)
    content {
      zone      = var.zone
      subnet_id = var.subnet_id
    }
  }
}
