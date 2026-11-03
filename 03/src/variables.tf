###cloud vars

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}
variable "default_cidr" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}

variable "vpc_name" {
  type        = string
  default     = "develop"
  description = "VPC network&subnet name"
}
###common vm vars

variable "vm_image_family" {
  type        = string
  default     = "ubuntu-2004-lts"
  description = "Image family for all VMs"
}

variable "vm_platform_id" {
  type        = string
  default     = "standard-v3"
  description = "Platform id for all VMs"
}

variable "vm_preemptible" {
  type        = bool
  default     = true
  description = "All VMs are preemptible"
}

variable "vm_nat" {
  type        = bool
  default     = true
  description = "Assign external IP to VMs"
}

variable "vm_core_fraction" {
  type        = number
  default     = 20
  description = "Guaranteed vCPU share in percent"
}

variable "vm_user" {
  type        = string
  default     = "ubuntu"
  description = "User for ssh-keys in metadata"
}

variable "ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
  description = "Path to the public ssh key"
}

###web vms (count)

variable "web_vm" {
  type = object({
    name_prefix = string
    vm_count    = number
    cpu         = number
    ram         = number
    disk_volume = number
  })
  default = {
    name_prefix = "web"
    vm_count    = 2
    cpu         = 2
    ram         = 1
    disk_volume = 5
  }
  description = "Parameters of identical web VMs (count)"
}

###db vms (for_each)

variable "each_vm" {
  type = list(object({
    vm_name     = string
    cpu         = number
    ram         = number
    disk_volume = number
  }))
  default = [
    { vm_name = "main", cpu = 4, ram = 4, disk_volume = 10 },
    { vm_name = "replica", cpu = 2, ram = 2, disk_volume = 5 }
  ]
  description = "Different db VMs (for_each)"
}

###extra disks and storage vm

variable "extra_disks" {
  type = object({
    disk_count  = number
    name_prefix = string
    type        = string
    size        = number
  })
  default = {
    disk_count  = 3
    name_prefix = "disk"
    type        = "network-hdd"
    size        = 1
  }
  description = "Parameters of identical extra disks (count)"
}

variable "storage_vm" {
  type = object({
    name        = string
    cpu         = number
    ram         = number
    disk_volume = number
  })
  default = {
    name        = "storage"
    cpu         = 2
    ram         = 1
    disk_volume = 5
  }
  description = "Parameters of the single storage VM"
}

###ansible inventory

variable "inventory_template" {
  type        = string
  default     = "hosts.tftpl"
  description = "Template file for the ansible inventory"
}

variable "inventory_file" {
  type        = string
  default     = "hosts.ini"
  description = "Generated ansible inventory file"
}

variable "playbook_file" {
  type        = string
  default     = "playbook.yml"
  description = "Ansible playbook applied to all VMs"
}
