output "vms_info" {
  description = "List of maps containing name, id, and fqdn for count and for_each instances"
  value = concat(
    [
      for vm in yandex_compute_instance.web : {
        name = vm.name
        id   = vm.id
        fqdn = vm.fqdn
      }
    ],
    [
      for vm in values(yandex_compute_instance.db) : {
        name = vm.name
        id   = vm.id
        fqdn = vm.fqdn
      }
    ]
  )
}
