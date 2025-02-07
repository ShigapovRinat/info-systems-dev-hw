output "ssh_command" {
  value = "ssh -i ${path.module}/id_rsa ipiris@${yandex_compute_instance.vm.network_interface.0.nat_ip_address}"
}

output "web_url" {
  value = "http://${yandex_compute_instance.vm.network_interface.0.nat_ip_address}"
}
