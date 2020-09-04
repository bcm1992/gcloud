resource "google_compute_instance" "vm_instance" {
  count = 4
  name         = format("linux-foundation-%s", count.index + 1)
  machine_type = "n1-standard-2"
  zone    = "us-west1-c"

  boot_disk {
    initialize_params {
      #image = "gce-uefi-images/ubuntu-1804-lts"
      image = "ubuntu-1604-lts"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network       = "default"
    network_ip    = count.index == 0 ? var.kube_admin_private_ip : ""
    access_config {
    }
  }

  scheduling {
    preemptible = true
    automatic_restart  = false
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.gce_ssh_pub_key_file)},${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }


  provisioner "file" {
    source      = "files/kube_deploy.sh"
    destination = "/home/ubuntu/kube_deploy.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.gce_ssh_private_key_file)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }
    provisioner "file" {
    source      = "files/kube_deploy_crio.sh"
    destination = "/home/ubuntu/kube_deploy_crio.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.gce_ssh_private_key_file)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  provisioner "file" {
    source      = "files/ubuntu.rsa"
    destination = "/home/ubuntu/ubuntu.rsa"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.gce_ssh_private_key_file)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  provisioner "local-exec" {
    command = "tar zcf ./files/yaml_files.tar.gz ./files/ckad ./files/cka"
  }

  provisioner "file" {
    source      = "./files/yaml_files.tar.gz"
    destination = "/home/ubuntu/yaml_files.tar.gz"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.gce_ssh_private_key_file)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 755 /home/ubuntu/kube_deploy_crio.sh",
      "chmod 755 /home/ubuntu/kube_deploy.sh",
      "sudo /home/ubuntu/kube_deploy.sh",
#      "sudo /home/ubuntu/kube_deploy_crio.sh",
      "tar xf yaml_files.tar.gz"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.gce_ssh_private_key_file)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }
}