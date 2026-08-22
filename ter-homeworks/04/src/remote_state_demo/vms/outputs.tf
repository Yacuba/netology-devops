# Output external IP for Marketing VM
output "vm_marketing_external_ip" {
  value       = [for vm in module.marketing_vm.all : vm.network_interface[0].nat_ip_address]
  description = "External IP address of Marketing VM"
}

# Output external IP for Analytics VM (if declared)
output "vm_analytics_external_ip" {
  value       = [for vm in module.analytics_vm.all : vm.network_interface[0].nat_ip_address]
  description = "External IP address of Analytics VM"
}
