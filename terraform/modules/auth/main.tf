variable "project_id" {
  type = string
}

variable "google_oauth_client_id" {
  type      = string
  sensitive = true
}

variable "google_oauth_client_secret" {
  type      = string
  sensitive = true
}

resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.project_id
}

resource "google_identity_platform_config" "auth_config" {
  provider = google-beta
  project  = google_firebase_project.default.project
}

resource "google_identity_platform_default_supported_idp_config" "google_signin" {
  provider      = google-beta
  project       = google_firebase_project.default.project
  enabled       = true
  idp_id        = "google.com"
  client_id     = var.google_oauth_client_id
  client_secret = var.google_oauth_client_secret
}
