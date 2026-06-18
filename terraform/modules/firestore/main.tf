variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.region

  type = "FIRESTORE_NATIVE"

  delete_protection_state = "DELETE_PROTECTION_DISABLED"

  deletion_policy = "DELETE"
}
