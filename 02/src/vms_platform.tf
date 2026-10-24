###common vars

variable "vms_resources" {
  type = map(object({
    cores         = number
    memory        = number
    core_fraction = number
    hdd_size      = number
    hdd_type      = string
  }))
  default = {
    web = {
      cores         = 2
      memory        = 1
      core_fraction = 20
      hdd_size      = 5
      hdd_type      = "network-hdd"
    }
    db = {
      cores         = 2
      memory        = 2
      core_fraction = 20
      hdd_size      = 5
      hdd_type      = "network-hdd"
    }
  }
  description = "Resources of all VMs: web and db"
}

variable "metadata" {
  type = map(string)
  default = {
    serial-port-enable = "1"
    ssh-keys           = "set real value in personal.auto.tfvars"
  }
  description = "Metadata common for all VMs"
}

###vm_web vars

variable "vm_web_image_family" {
  type        = string
  default     = "ubuntu-2004-lts"
  description = "Image family for the web VM"
}

variable "vm_web_platform_id" {
  type        = string
  default     = "standard-v3"
  description = "Platform id of the web VM"
}

variable "vm_web_preemptible" {
  type        = bool
  default     = true
  description = "Is the web VM preemptible"
}

variable "vm_web_nat" {
  type        = bool
  default     = true
  description = "Assign external IP to the web VM"
}

###vm_db vars

variable "vm_db_zone" {
  type        = string
  default     = "ru-central1-e"
  description = "Zone of the db VM (ru-central1-b is not available in this cloud)"
}

variable "vm_db_cidr" {
  type        = list(string)
  default     = ["10.0.2.0/24"]
  description = "CIDR of the db subnet"
}

variable "vm_db_platform_id" {
  type        = string
  default     = "standard-v3"
  description = "Platform id of the db VM"
}

variable "vm_db_preemptible" {
  type        = bool
  default     = true
  description = "Is the db VM preemptible"
}

variable "vm_db_nat" {
  type        = bool
  default     = true
  description = "Assign external IP to the db VM"
}

###unused after vms_resources and metadata (commented out)

# variable "vm_web_name" {
#   type    = string
#   default = "netology-develop-platform-web"
# }
# variable "vm_web_cores" {
#   type    = number
#   default = 2
# }
# variable "vm_web_memory" {
#   type    = number
#   default = 1
# }
# variable "vm_web_core_fraction" {
#   type    = number
#   default = 20
# }
# variable "vm_web_serial_port_enable" {
#   type    = number
#   default = 1
# }
# variable "vm_db_name" {
#   type    = string
#   default = "netology-develop-platform-db"
# }
# variable "vm_db_cores" {
#   type    = number
#   default = 2
# }
# variable "vm_db_memory" {
#   type    = number
#   default = 2
# }
# variable "vm_db_core_fraction" {
#   type    = number
#   default = 20
# }
# variable "vm_db_serial_port_enable" {
#   type    = number
#   default = 1
# }
