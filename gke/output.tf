output "version" {
  value = ["${google_container_node_pool.primary_preemptible_nodes.*.version}"]
}