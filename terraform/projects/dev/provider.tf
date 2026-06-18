locals {
  project_id = "${var.project_id_prefix}-${basename(path.cwd)}"
}

terraform {
  required_version = ">= 1.14.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.0"
    }
  }
  backend "gcs" {}
}

provider "google" {
  project = local.project_id
  region  = var.region
}

provider "google-beta" {
  project               = local.project_id
  region                = var.region
  user_project_override = true
  billing_project       = local.project_id
}
