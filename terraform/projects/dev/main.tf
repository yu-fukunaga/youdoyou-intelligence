module "services" {
  source     = "../../modules/services"
  project_id = local.project_id
}

module "iam" {
  source     = "../../modules/iam"
  project_id = local.project_id
}

module "registry" {
  source     = "../../modules/registry"
  project_id = local.project_id
  region     = var.region
}

module "secrets" {
  source     = "../../modules/secrets"
  project_id = local.project_id
}

module "firestore" {
  source     = "../../modules/firestore"
  project_id = local.project_id
  region     = var.region
}

data "google_secret_manager_secret_version" "google_oauth_client_id" {
  secret  = "google-oauth-client-id"
  project = local.project_id
  version = "latest"

  depends_on = [module.secrets]
}

data "google_secret_manager_secret_version" "google_oauth_client_secret" {
  secret  = "google-oauth-client-secret"
  project = local.project_id
  version = "latest"

  depends_on = [module.secrets]
}

module "auth" {
  source                     = "../../modules/auth"
  project_id                 = local.project_id
  google_oauth_client_id     = data.google_secret_manager_secret_version.google_oauth_client_id.secret_data
  google_oauth_client_secret = data.google_secret_manager_secret_version.google_oauth_client_secret.secret_data
}

module "cloudrun" {
  source                = "../../modules/cloudrun"
  project_id            = local.project_id
  region                = var.region
  service_account_email = module.iam.app_runner_sa_email
  image                 = "asia-northeast1-docker.pkg.dev/${local.project_id}/server/server:latest"

  env_vars = {
    GCP_PROJECT_ID = local.project_id
    ENV            = "development"
  }

  secret_env_vars = {
    GOOGLE_API_KEY = {
      secret_id = "google-api-key"
      version   = "latest"
    }
  }
}
