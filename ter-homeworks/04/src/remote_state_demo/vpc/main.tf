module "vpc" {
  source   = "../../vpc"
  env_name = var.vpc_name
  subnets  = var.subnets
}
