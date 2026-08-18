output "cluster_id" {
  value       = yandex_mdb_mysql_cluster.cluster.id
  description = "MySQL cluster ID"
}

output "cluster_name" {
  value       = yandex_mdb_mysql_cluster.cluster.name
  description = "MySQL cluster name"
}
