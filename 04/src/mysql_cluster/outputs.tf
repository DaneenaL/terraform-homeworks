output "cluster_id" {
  description = "Id of the MySQL cluster"
  value       = yandex_mdb_mysql_cluster.this.id
}
