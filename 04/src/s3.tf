resource "random_string" "bucket_suffix" {
  length  = 8
  upper   = false
  lower   = true
  numeric = true
  special = false
}

module "s3" {
  source = "git::https://github.com/terraform-yc-modules/terraform-yc-s3.git"

  bucket_name = "${var.s3_bucket_prefix}-${random_string.bucket_suffix.result}"
  folder_id   = var.folder_id
  max_size    = var.s3_max_size
}
