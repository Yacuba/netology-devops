locals {
  company  = "netology"
  env      = "develop"
  web_type = "platform-web"
  db_type  = "platform-db"

  vm_web_name = "${local.company}-${local.env}-${local.web_type}"
  vm_db_name  = "${local.company}-${local.env}-${local.db_type}"
}