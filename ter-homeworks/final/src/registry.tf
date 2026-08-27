# Yandex Container Registry
resource "yandex_container_registry" "registry" {
  name      = local.registry_name
  folder_id = var.folder_id
}
