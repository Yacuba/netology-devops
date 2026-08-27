locals {
  name_prefix = "${var.project_name}-${var.environment}"

  vpc_name      = "${local.name_prefix}-vpc"
  subnet_name   = "${local.name_prefix}-subnet-${var.default_zone}"
  sg_name       = "${local.name_prefix}-sg"
  registry_name = "${local.name_prefix}-registry"
  mysql_name    = "${local.name_prefix}-mysql"
  lockbox_name  = "${local.name_prefix}-db-secret"
  vm_name       = "${local.name_prefix}-web-vm"
}
