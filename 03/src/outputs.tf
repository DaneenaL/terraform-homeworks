output "vms_info" {
  description = "Name, id and internal fqdn of VMs created with count and for_each"
  value = concat(
    [for vm in yandex_compute_instance.web : {
      name = vm.name
      id   = vm.id
      fqdn = vm.fqdn
    }],
    [for vm in values(yandex_compute_instance.db) : {
      name = vm.name
      id   = vm.id
      fqdn = vm.fqdn
    }]
  )
}
