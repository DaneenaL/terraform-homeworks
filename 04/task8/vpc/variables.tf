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

variable "vpc_name" {
  type        = string
  default     = "split"
  description = "Network name"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.20.1.0/24"
  description = "CIDR of the subnet"
}
