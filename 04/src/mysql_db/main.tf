resource "yandex_mdb_mysql_database" "this" {
  cluster_id = var.cluster_id
  name       = var.db_name
}

resource "yandex_mdb_mysql_user" "this" {
  cluster_id = var.cluster_id
  name       = var.user_name
  password   = var.user_password

  permission {
    database_name = yandex_mdb_mysql_database.this.name
    roles         = var.user_roles
  }
}
