resource "yandex_mdb_mysql_cluster" "cluster" {
  #checkov:skip=CKV_YC_1:Security group is not required for demo environment
  name        = var.cluster_name
  environment = var.environment
  network_id  = var.network_id
  version     = var.version_mysql

  resources {
    resource_preset_id = var.resource_preset_id
    disk_type_id       = var.disk_type_id
    disk_size          = var.disk_size
  }

  dynamic "host" {
    for_each = var.HA ? slice(var.hosts, 0, var.host_count) : slice(var.hosts, 0, 1)
    content {
      zone      = host.value.zone
      subnet_id = host.value.subnet_id
    }
  }
}
