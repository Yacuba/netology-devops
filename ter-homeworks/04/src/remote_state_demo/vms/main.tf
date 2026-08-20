# Data source reading state of the independent VPC root module
data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../vpc/terraform.tfstate"
  }
}

data "template_file" "cloudinit" {
  template = file("${path.module}/cloud-init.yml")
  vars = {
    ssh_public_key = var.vms_ssh_root_key
  }
}

# Deploy VM using outputs from remote state
# Marketing VM
module "marketing_vm" {
  source         = "git::https://github.com/udjin10/yandex_compute_instance.git?ref=de7090ae115ee5059cd81053a808af079c325e01"
  env_name       = var.vm_marketing.env_name
  network_id     = data.terraform_remote_state.vpc.outputs.network_id
  subnet_zones   = [var.default_zone]
  subnet_ids     = [data.terraform_remote_state.vpc.outputs.subnets[var.default_zone].id]
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
  network_id     = data.terraform_remote_state.vpc.outputs.network_id
  subnet_zones   = [var.default_zone]
  subnet_ids     = [data.terraform_remote_state.vpc.outputs.subnets[var.default_zone].id]
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
