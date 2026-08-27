# Security Group with dynamic ingress rules
resource "yandex_vpc_security_group" "sg" {
  name        = local.sg_name
  description = "Security group for ${local.name_prefix}"
  network_id  = yandex_vpc_network.vpc.id

  # Dynamic generation of external ingress rules
  dynamic "ingress" {
    for_each = var.security_group_ingress_rules
    content {
      protocol       = ingress.value.protocol
      description    = ingress.value.description
      port           = ingress.value.port
      v4_cidr_blocks = ingress.value.v4_cidr_blocks
    }
  }

  # Allow internal traffic within security group (App <-> DB)
  ingress {
    protocol          = "ANY"
    description       = "Allow internal traffic within security group"
    predefined_target = "self_security_group"
  }

  # Outbound Internet traffic
  egress {
    protocol       = "ANY"
    description    = "Allow all outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}
