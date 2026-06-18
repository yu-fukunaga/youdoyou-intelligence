variable "project_id" {
  type = string
}

locals {
  secret_ids = [
    "google-api-key",
    "google-oauth-client-id",
    "google-oauth-client-secret",
  ]
}

resource "google_secret_manager_secret" "this" {
  for_each  = toset(local.secret_ids)
  project   = var.project_id
  secret_id = each.key

  replication {
    auto {}
  }
}
