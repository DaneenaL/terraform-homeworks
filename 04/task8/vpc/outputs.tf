output "network_id" {
  description = "Network id for the vms root module"
  value       = module.vpc.network_id
}

output "subnet_id" {
  description = "Subnet id for the vms root module"
  value       = module.vpc.subnets[var.default_zone].id
}
