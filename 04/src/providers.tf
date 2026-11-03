terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 1.12.0"
}

provider "yandex" {
  service_account_key_file = file("~/.authorized_key.json")
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.default_zone
}

# The s3 module uses the aws provider only to render policy JSON, no calls to AWS are made.
# Keys are dummy values, the checks that need real AWS are switched off.
provider "aws" {
  region                      = var.aws_region
  access_key                  = "not-used"
  secret_key                  = "not-used"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
}
