provider "google" {
  credentials = "${file("My First Project-c3bbcc37a8b1.json")}"
  project = "centered-loader-225320"
  region  = "us-east1"
  zone    = "us-east1-b"
}
resource "google_compute_network" "vpc_network" {
  name                    = "terraform-network"
  auto_create_subnetworks = "true"
}

// Managed instance group
resource "google_compute_region_instance_group_manager" "cs" {
  name                      = "${var.service_name}"
  base_instance_name        = "${var.service_name}"
  instance_template         = "${google_compute_instance_template.cs.self_link}"
  region                    = "${var.service_project_region}"
  target_size               = "${var.instance_group_size}"
    
    named_port {
    name = "${var.port_name}"
    port = "${var.port_number}"
    }
}

//Instance template
resource "google_compute_instance_template" "cs" {
  name_prefix  = "${var.service_name}"
  machine_type = "${var.instance_machine_type}"
  tags         = "${var.instance_tags}"
  region       = "${var.service_project_region}"

  labels = {
    environment = "prod"
  }

  // The boot disk for the instance
  disk {
    source_image = "${var.instance_image}"
    auto_delete  = true
    boot         = true
    disk_size_gb = "${var.persistent_disk_size}"
  }

  labels = {
    service     = "${var.service_name}"
    environment = "${var.environment}"
  }

  scheduling {
    automatic_restart = true
  }

  lifecycle {
    create_before_destroy = true
  }

  //Networking
network_interface {
    # A default network is created for all GCP projects
    network       = "${google_compute_network.vpc_network.self_link}"
    access_config = {
    }
  }
  metadata {

  metadata_startup_script = "${file("scripts/startup.sh")}"
  }
  service_account {
    scopes = ["cloud-platform"]
  }
}

