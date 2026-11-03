variable "env_name" {
  type        = string
  description = "Name of the network, also used in the subnet names"
}

variable "subnets" {
  type = list(object({
    zone = string
    cidr = string
  }))
  description = "Subnets to create: availability zone and CIDR of each one"
}
