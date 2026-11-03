variable "cluster_id" {
  type        = string
  description = "Id of the existing MySQL cluster"
}

variable "db_name" {
  type        = string
  description = "Name of the database"
}

variable "user_name" {
  type        = string
  description = "Name of the database user"
}

variable "user_password" {
  type        = string
  sensitive   = true
  description = "Password of the database user"
}

variable "user_roles" {
  type        = list(string)
  default     = ["ALL"]
  description = "Roles of the user on the database"
}
