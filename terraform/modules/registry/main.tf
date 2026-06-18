variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

resource "google_artifact_registry_repository" "app_repo" {
  project       = var.project_id
  location      = var.region
  repository_id = "server"
  description   = "Artifact Registry for application container images"
  format        = "DOCKER"

  cleanup_policy_dry_run = false

  cleanup_policies {
    id     = "keep-recent-10"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }

  cleanup_policies {
    id     = "delete-old-images"
    action = "DELETE"
    condition {
      tag_state  = "ANY"
      older_than = "2592000s"
    }
  }
}

output "repository_uri" {
  value = google_artifact_registry_repository.app_repo.registry_uri
}
