data "vault_generic_secret" "vault_example" {
  path = var.secret_path
}

output "vault_example" {
  value = nonsensitive(data.vault_generic_secret.vault_example.data)
}

resource "vault_generic_secret" "from_terraform" {
  path      = var.new_secret_path
  data_json = jsonencode(var.new_secret_data)
}
