output "database_name" {
  value       = yandex_mdb_mysql_database.db.name
  description = "Created database name"
}

output "user_name" {
  value       = yandex_mdb_mysql_user.user.name
  description = "Created user name"
}
