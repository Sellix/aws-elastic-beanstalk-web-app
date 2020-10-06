locals {
  tags = {
    "Name"        = "web-app-${var.environment_check}"
    "Project"     = "sellix-web-app-${var.environment_check}"
    "Environment" = "${var.environment_check}"
  }
  env = {
    ELASTIC_BEANSTALK_PORT = 8080
    DOMAIN            = local.production ? "sellix.io" : "sellix.gg"
    ENVIRONMENT       = local.production ? "production" : "staging"
  }
  production = var.environment_check == "production" ? true : false
}