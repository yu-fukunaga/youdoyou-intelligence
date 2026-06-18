variable "project_id" {
  type = string
}

locals {
  services = [
    "cloudresourcemanager.googleapis.com", # IAMポリシー取得に必要
    "run.googleapis.com",                  # Cloud Run
    "firestore.googleapis.com",            # Firestore
    "secretmanager.googleapis.com",        # Secret Manager
    "identitytoolkit.googleapis.com",      # Firebase Auth
    "firebase.googleapis.com",             # Firebase
    "iam.googleapis.com",                  # IAM
    "iamcredentials.googleapis.com",       # IAM Credentials
    "sts.googleapis.com",                  # STS
    "cloudbuild.googleapis.com",           # Cloud Build
    "eventarc.googleapis.com",             # Eventarc 本体
    "pubsub.googleapis.com",               # Eventarc の裏側で使われる
    "calendar-json.googleapis.com",        # Google Calendar API
    "compute.googleapis.com",              # VPC subnetworkに必要
  ]
}

resource "google_project_service" "enabled_services" {
  for_each = toset(local.services)
  project  = var.project_id
  service  = each.key

  disable_on_destroy = false
}
