variable "cluster_name" {
  type        = string
  description = "Name of the MySQL cluster"
}

variable "network_id" {
  type        = string
  description = "Id of the network where the cluster lives"
}

variable "subnet_id" {
  type        = string
  description = "Subnet for the cluster hosts"
}

variable "zone" {
  type        = string
  description = "Availability zone of the cluster hosts, must match the subnet"
}

variable "HA" {
  type        = bool
  default     = false
  description = "true creates ha_hosts_count hosts, false creates a single host"
}

variable "ha_hosts_count" {
  type        = number
  default     = 2
  description = "Number of hosts when HA is true"
}

variable "environment" {
  type        = string
  default     = "PRESTABLE"
  description = "PRESTABLE or PRODUCTION"
}

variable "mysql_version" {
  type        = string
  default     = "8.0"
  description = "MySQL version"
}

variable "resource_preset_id" {
  type        = string
  default     = "b2.medium"
  description = "Host class, b2.medium is the cheapest one available in zone d"
}

variable "disk_type_id" {
  type        = string
  default     = "network-hdd"
  description = "Disk type of the hosts"
}

variable "disk_size" {
  type        = number
  default     = 10
  description = "Disk size of a host in GB"
}
