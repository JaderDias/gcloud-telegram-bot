provider "google" {
  project = var.project
  region  = var.region
}

resource "google_app_engine_application" "app" {
  project       = var.project
  location_id   = var.location_id
  database_type = "CLOUD_FIRESTORE"
}

resource "google_storage_bucket" "bucket" {
  name     = "${var.project}-bucket"
  location = "US"
}

module "echobot" {
  source               = "./modules/function"
  project              = var.project
  function_name        = "echobot"
  function_entry_point = "app"
  pubsub_topic_name    = "echobot_trigger"
  source_bucket_name   = google_storage_bucket.bucket.name
  source_dir           = abspath("../python/echobot")
  timeout              = 540 # 9 minutes
  depends_on = [
    google_app_engine_application.app,
  ]
}

module "token" {
    source     = "./modules/secret"
    acessor    = module.echobot.service_account_email
    id         = "telegram-bot-token"
    value      = "${var.token}"
    depends_on = [
        module.echobot,
    ]
}

resource "google_cloud_scheduler_job" "echobot_job" {
  name        = "echobot_job"
  description = "triggers echobot every 8 minutes"
  schedule    = "*/8 * * * *"

  pubsub_target {
    topic_name = "projects/${var.project}/topics/echobot_trigger"
    data       = base64encode("test")
  }
  depends_on = [
    module.token,
  ]
}