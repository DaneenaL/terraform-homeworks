resource "yandex_vpc_network" "this" {
  name = var.env_name
}

resource "yandex_vpc_subnet" "this" {
  for_each = { for s in var.subnets : s.zone => s }

  name           = "${var.env_name}-${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [each.value.cidr]
}
