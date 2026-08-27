# Managed Service for MySQL Cluster
resource "yandex_mdb_mysql_cluster" "mysql" {
  name               = local.mysql_name
  environment        = var.mysql_cluster_config.environment
  network_id         = yandex_vpc_network.vpc.id
  version            = var.mysql_cluster_config.version
  security_group_ids = [yandex_vpc_security_group.sg.id]

  resources {
    resource_preset_id = var.mysql_cluster_config.resource_preset_id
    disk_type_id       = var.mysql_cluster_config.disk_type_id
    disk_size          = var.mysql_cluster_config.disk_size
  }

  host {
    zone             = var.default_zone
    subnet_id        = yandex_vpc_subnet.subnet.id
    assign_public_ip = var.mysql_cluster_config.assign_public_ip
  }

  # Ensure Lockbox secret version exists before creating cluster user
  depends_on = [yandex_lockbox_secret_version.mysql_password_version]
}

# MySQL Database
resource "yandex_mdb_mysql_database" "db" {
  cluster_id = yandex_mdb_mysql_cluster.mysql.id
  name       = var.mysql_db_config.db_name
}

# MySQL User reading password from Lockbox
resource "yandex_mdb_mysql_user" "user" {
  cluster_id = yandex_mdb_mysql_cluster.mysql.id
  name       = var.mysql_db_config.username
  password   = [for entry in data.yandex_lockbox_secret_version.mysql_password_data.entries : entry.text_value if entry.key == var.lockbox_secret_key][0]

  permission {
    database_name = yandex_mdb_mysql_database.db.name
    roles         = var.mysql_db_config.roles
  }
}
