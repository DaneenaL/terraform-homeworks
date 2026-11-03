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

###common vars

variable "vms_ssh_root_key" {
  type        = string
  default     = "your_ssh_ed25519_key"
  description = "ssh-keygen -t ed25519"
}

###example vm_web var
variable "vm_web_name" {
  type        = string
  default     = "netology-develop-platform-web"
  description = "example vm_web_ prefix"
}

###example vm_db var
variable "vm_db_name" {
  type        = string
  default     = "netology-develop-platform-db"
  description = "example vm_db_ prefix"
}




###vm vars (task 1)

variable "vm_ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
  description = "Path to the public ssh key that goes to cloud-init"
}

variable "vm_user" {
  type        = string
  default     = "ubuntu"
  description = "User created on the VMs by cloud-init"
}

variable "vm_image_family" {
  type        = string
  default     = "ubuntu-2004-lts"
  description = "Image family for the VMs"
}

variable "vm_env_name" {
  type        = string
  default     = "develop"
  description = "Environment name passed to the VM modules"
}

variable "vm_public_ip" {
  type        = bool
  default     = true
  description = "Assign public IP to the VMs"
}

variable "vm_instance_count" {
  type        = number
  default     = 1
  description = "How many VMs each module call creates"
}

variable "projects" {
  type = object({
    marketing = string
    analytics = string
  })
  default = {
    marketing = "marketing"
    analytics = "analytics"
  }
  description = "Project names used in VM names and labels"
}

variable "vm_owner" {
  type        = string
  default     = "daneenal"
  description = "Value of the owner label"
}

variable "vm_platform_id" {
  type        = string
  default     = "standard-v3"
  description = "Platform of the VMs"
}

variable "vm_core_fraction" {
  type        = number
  default     = 20
  description = "Guaranteed CPU share, 20 is the minimum for standard-v3"
}

variable "vm_preemptible" {
  type        = bool
  default     = true
  description = "Preemptible VMs to save money"
}

###vpc module vars (task 4)

variable "vpc_prod_name" {
  type        = string
  default     = "production"
  description = "Name of the production network"
}

variable "prod_subnets" {
  type = list(object({
    zone = string
    cidr = string
  }))
  default = [
    { zone = "ru-central1-a", cidr = "10.10.1.0/24" },
    { zone = "ru-central1-b", cidr = "10.10.2.0/24" },
    { zone = "ru-central1-d", cidr = "10.10.3.0/24" },
  ]
  description = "Subnets of the production network, one per availability zone"
}

###s3 bucket vars (task 6)

variable "s3_bucket_prefix" {
  type        = string
  default     = "netology-bucket"
  description = "Prefix of the bucket name, a random suffix is added to keep it unique"
}

variable "s3_max_size" {
  type        = number
  default     = 1073741824
  description = "Maximum bucket size in bytes (1 GB)"
}

variable "aws_region" {
  type        = string
  default     = "ru-central1"
  description = "Region name for the aws provider, it is only used to build the policy JSON in the s3 module"
}

###mysql vars (task 5)

variable "mysql_cluster_name" {
  type        = string
  default     = "example"
  description = "Name of the MySQL cluster"
}

variable "mysql_ha" {
  type        = bool
  default     = true
  description = "false is a single host cluster, true is a cluster of two hosts"
}

variable "mysql_db_name" {
  type        = string
  default     = "test"
  description = "Name of the database created in the cluster"
}

variable "mysql_user_name" {
  type        = string
  default     = "app"
  description = "Name of the database user"
}
