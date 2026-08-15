# Generate Ansible inventory file from template
resource "local_file" "hosts_cfg" {
  content = templatefile("${path.module}/hosts.tftpl", {
    webservers = yandex_compute_instance.web
    databases  = values(yandex_compute_instance.db)
    storage    = [yandex_compute_instance.storage]
  })
  filename = "${path.module}/hosts.cfg"
}

# Run Ansible Playbook via local-exec provisioner
resource "null_resource" "web_hosts_provision" {
  depends_on = [
    yandex_compute_instance.web,
    yandex_compute_instance.db,
    yandex_compute_instance.storage,
    local_file.hosts_cfg
  ]

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i ${abspath(path.module)}/hosts.cfg ${abspath(path.module)}/test.yml"
    on_failure = continue
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }

  triggers = {
    always_run = timestamp()
  }
}
