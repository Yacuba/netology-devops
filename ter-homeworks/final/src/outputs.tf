output "registry_id" {
  value       = yandex_container_registry.registry.id
  description = "Yandex Container Registry ID"
}

output "mysql_cluster_id" {
  value       = yandex_mdb_mysql_cluster.mysql.id
  description = "MySQL Cluster ID"
}

output "mysql_host_fqdn" {
  value       = yandex_mdb_mysql_cluster.mysql.host[0].fqdn
  description = "MySQL Host FQDN"
}

output "mysql_user" {
  value       = var.mysql_db_config.username
  description = "MySQL Username"
}

output "mysql_database" {
  value       = var.mysql_db_config.db_name
  description = "MySQL Database Name"
}

output "mysql_password" {
  value       = [for entry in data.yandex_lockbox_secret_version.mysql_password_data.entries : entry.text_value if entry.key == var.lockbox_secret_key][0]
  description = "MySQL Password from Lockbox"
  sensitive   = true
}

output "lockbox_secret_id" {
  value       = yandex_lockbox_secret.mysql_secret.id
  description = "Lockbox Secret ID"
}

output "vm_public_ip" {
  value       = yandex_compute_instance.web.network_interface[0].nat_ip_address
  description = "Public IP address of Web VM"
}

output "vm_fqdn" {
  value       = yandex_compute_instance.web.fqdn
  description = "FQDN of Web VM"
}
