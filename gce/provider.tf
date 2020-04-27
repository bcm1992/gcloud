provider "google" {
  project = var.project_id
  region  = "us-west1"
  zone    = "us-west1-b"
}
terraform {
  backend "http" { 
    address = "https://objectstorage.us-phoenix-1.oraclecloud.com/p/9G3K5DO8X4o5A-h_7pKSPfDS4QGeEoQm8rxDY40HGfo/n/axtee0lnkutf/b/terraform-gcloud/o/terraform-gce.tfstate"
    update_method = "PUT" 
  }
}
