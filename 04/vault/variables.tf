variable "vault_address" {
  type        = string
  default     = "http://127.0.0.1:8200"
  description = "Address of the local Vault from docker-compose"
}

variable "vault_token" {
  type        = string
  default     = "education"
  sensitive   = true
  description = "Dev root token of the local Vault, it is public in the task and docker-compose"
}

variable "secret_path" {
  type        = string
  default     = "secret/example"
  description = "Path of the secret created in the web interface"
}

variable "new_secret_path" {
  type        = string
  default     = "secret/from_terraform"
  description = "Path of the secret that Terraform writes itself"
}

variable "new_secret_data" {
  type        = map(string)
  default     = { hello = "written by terraform" }
  description = "Data of the secret that Terraform writes to Vault"
}
