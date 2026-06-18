variable "project_id" {
  type = string
}

# =============================================================================
# SA for Cloud Build
# =============================================================================
resource "google_service_account" "cloudbuild_sa" {
  account_id   = "cloudbuild-worker-sa"
  display_name = "Cloud Build Worker Service Account"
}

locals {
  cloudbuild_roles = [
    "roles/logging.logWriter",
    "roles/artifactregistry.writer",
    "roles/storage.objectAdmin",
    "roles/run.developer",
  ]
}

resource "google_project_iam_member" "cloudbuild_scoped_roles" {
  for_each = toset(local.cloudbuild_roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.cloudbuild_sa.email}"
}

resource "google_service_account_iam_member" "cloudbuild_impersonate_app_runner" {
  service_account_id = google_service_account.app_runner.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cloudbuild_sa.email}"
}

# =============================================================================
# SA for Cloud Run
# =============================================================================
resource "google_service_account" "app_runner" {
  account_id   = "app-runner-sa"
  display_name = "Cloud Run Runtime Service Account"
}

locals {
  app_roles = [
    "roles/datastore.user",
    "roles/logging.logWriter",
    "roles/secretmanager.secretAccessor",
  ]
}

resource "google_project_iam_member" "app_scoped_roles" {
  for_each = toset(local.app_roles)

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.app_runner.email}"
}

# =============================================================================
# Outputs
# =============================================================================
output "cloudbuild_sa_email" {
  value = google_service_account.cloudbuild_sa.email
}

output "app_runner_sa_email" {
  value = google_service_account.app_runner.email
}
