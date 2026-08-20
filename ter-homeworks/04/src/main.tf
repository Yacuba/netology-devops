# resource "yandex_vpc_network" "develop" {
#   name = var.vpc_name
# }
# resource "yandex_vpc_subnet" "develop" {
#   name           = var.vpc_name
#   zone           = var.default_zone
#   network_id     = yandex_vpc_network.develop.id
#   v4_cidr_blocks = var.default_cidr
# }

# module "vpc_dev" {
#   source   = "./vpc"
#   env_name = var.vpc_name
#   zone     = var.default_zone
#   cidr     = var.default_cidr[0]
# }

# Updated call of VPC module
module "vpc_dev" {
  source   = "./vpc"
  env_name = var.vpc_name
  subnets  = var.subnets_dev
}

data "template_file" "cloudinit" {
  template = file("${path.module}/cloud-init.yml")
  vars = {
    ssh_public_key = var.vms_ssh_root_key
  }
}

# Marketing VM
module "marketing_vm" {
  source         = "git::https://github.com/udjin10/yandex_compute_instance.git?ref=de7090ae115ee5059cd81053a808af079c325e01"
  env_name       = var.vm_marketing.env_name
  network_id     = module.vpc_dev.network_id
  subnet_zones   = [var.default_zone]
  subnet_ids     = [module.vpc_dev.subnets[var.default_zone].id]
  #subnet_ids     = [module.vpc_dev.subnet_id]
  instance_name  = var.vm_marketing.instance_name
  instance_count = var.vm_marketing.instance_count
  image_family   = var.vm_image_family
  public_ip      = var.vm_marketing.public_ip

  labels = { 
    owner   = var.vm_marketing.owner,
    project = var.vm_marketing.project
  }

  metadata = {
    user-data          = data.template_file.cloudinit.rendered
    serial-port-enable = var.serial_port_enable
  }
}

# Analytics VM
module "analytics_vm" {
  source         = "git::https://github.com/udjin10/yandex_compute_instance.git?ref=de7090ae115ee5059cd81053a808af079c325e01"
  env_name       = var.vm_analytics.env_name
  network_id     = module.vpc_dev.network_id
  subnet_zones   = [var.default_zone]
  subnet_ids     = [module.vpc_dev.subnets[var.default_zone].id]
  #subnet_ids     = [module.vpc_dev.subnet_id]  
  instance_name  = var.vm_analytics.instance_name
  instance_count = var.vm_analytics.instance_count
  image_family   = var.vm_image_family
  public_ip      = var.vm_analytics.public_ip

  labels = { 
    owner   = var.vm_analytics.owner,
    project = var.vm_analytics.project
  }

  metadata = {
    user-data          = data.template_file.cloudinit.rendered
    serial-port-enable = var.serial_port_enable
  }
}

# MySQL cluster
module "mysql_cluster" {
  source       = "./mysql_cluster"
  cluster_name = var.mysql_cluster_config.cluster_name
  network_id   = module.vpc_dev.network_id
  HA           = var.mysql_cluster_config.HA
  hosts = [
    for zone, subnet in module.vpc_dev.subnets : {
      zone      = zone
      subnet_id = subnet.id
    }
  ]
}

# DB and its user
module "mysql_db_user" {
  source     = "./mysql_db_user"
  cluster_id = module.mysql_cluster.cluster_id
  db_name    = var.mysql_db_config.db_name
  user_name  = var.mysql_db_config.user_name
}
