data "terraform_remote_state" "web-app-chatbot" {
  backend = "s3"
  config = {
    bucket     = "sellix-deployments"
    key        = "aws-chatbot.tfstate"
    region     = var.aws_region
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
  }
}

resource "aws_codestarnotifications_notification_rule" "web-app-codestarnotifications" {
  name           = "sellix-web-app-${var.environment_check}-chatbot"
  detail_type    = "BASIC"
  resource       = aws_codepipeline.web-app-codepipeline.arn
  status         = "ENABLED"
  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-started",
    "codepipeline-pipeline-pipeline-execution-succeeded",
    "codepipeline-pipeline-stage-execution-failed",
    "codepipeline-pipeline-action-execution-failed",
    "codepipeline-pipeline-manual-approval-succeeded",
  ]
  target {
    address = data.terraform_remote_state.web-app-chatbot.outputs.chatbot_arn
  }
}