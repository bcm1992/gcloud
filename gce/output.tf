output "hostname" {
  value = ["${google_compute_instance.vm_instance.*.name}"]
}

output "network_ip" {
  value = ["${google_compute_instance.vm_instance.*.network_interface.0.network_ip}"]
}

output "nat_ip" {
  value = ["${google_compute_instance.vm_instance.*.network_interface.0.access_config.0.nat_ip}"]
}

output "machine_type" {
  value = ["${google_compute_instance.vm_instance.*.machine_type}"]
}