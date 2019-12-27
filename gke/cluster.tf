resource "google_container_cluster" "primary" {
  name     = "my-gke-cluster"
  location = "us-west1"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = "us-west1"
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials --region ${google_container_cluster.primary.location} ${google_container_cluster.primary.name}"
  }

  provisioner "local-exec" {
    when       = destroy
    command    = "kubectl config delete-context gke_${var.project_id}_${self.location}_${google_container_cluster.primary.name}"
    on_failure = continue
  }
}
