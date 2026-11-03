variable "cloud_id" {
  type        = string
  description = "Cloud id"
}

variable "folder_id" {
  type        = string
  description = "Folder id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-d"
  description = "Availability zone"
}

variable "vm_name" {
  type        = string
  default     = "split"
  description = "Name of the VM"
}

variable "vm_env_name" {
  type        = string
  default     = "develop"
  description = "Environment name passed to the VM module"
}

variable "vm_user" {
  type        = string
  default     = "ubuntu"
  description = "User created on the VM by cloud-init"
}

variable "vm_ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
  description = "Path to the public ssh key"
}

variable "vm_image_family" {
  type        = string
  default     = "ubuntu-2004-lts"
  description = "Image family"
}

variable "vm_platform_id" {
  type        = string
  default     = "standard-v3"
  description = "Platform of the VM"
}

variable "vm_core_fraction" {
  type        = number
  default     = 20
  description = "Guaranteed CPU share"
}

variable "vm_preemptible" {
  type        = bool
  default     = true
  description = "Preemptible VM to save money"
}

variable "vm_public_ip" {
  type        = bool
  default     = true
  description = "Assign public IP"
}

variable "vpc_state_path" {
  type        = string
  default     = "../vpc/terraform.tfstate"
  description = "Path to the state file of the vpc root module"
}
