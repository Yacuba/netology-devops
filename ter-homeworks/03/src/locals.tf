locals {
  ssh_public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))

  vms_metadata = {
    serial-port-enable = var.serial_port_enable
    ssh-keys           = "${var.ssh_user}:${local.ssh_public_key}"
  }

  vpc = {
    "network_id" = "enp7i560tb28nageq0cc"
    "subnet_ids" = [
        "e9b0le401619ngf4h68n",
        "e2lbar6u8b2ftd7f5hia",
        "b0ca48coorjjq93u36pl",
        "fl8ner8rjsio6rcpcf0h",
    ]
    "subnet_zones" = [
        "ru-central1-a",
        "ru-central1-b",
        "ru-central1-c",
        "ru-central1-d",
    ]
  }  
}
