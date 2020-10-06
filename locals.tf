locals {
  tags = {
    "Name"        = "web-app-${var.environment_check}"
    "Project"     = "sellix-web-app-${var.environment_check}"
    "Environment" = "${var.environment_check}"
  }
  env_vars = {
    ELASTIC_BEANSTALK_PORT = 8080
    DOMAIN            = local.is_prod ? "sellix.io" : "sellix.gg"
    ENVIRONMENT       = local.is_prod ? "production" : "staging"
  }
  s3_key  = "elastic-beanstalk-web-app-${var.environment_check}.tfstate"
  is_prod = var.environment_check == "production" ? true : false
}