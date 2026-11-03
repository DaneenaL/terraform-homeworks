output "network_id" {
  description = "Id of the created network"
  value       = yandex_vpc_network.this.id
}

output "subnets" {
  description = "Created yandex_vpc_subnet resources, key is the zone"
  value       = yandex_vpc_subnet.this
}
