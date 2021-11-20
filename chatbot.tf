data "terraform_remote_state" "sellix-web-app-chatbot-terraform-state" {
  backend = "s3"
  config  = {
    bucket     = "sellix-deployments"
    key        = "aws-chatbot.tfstate"
    region     = "eu-west-1"
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
  }
}

resource "aws_codestarnotifications_notification_rule" "sellix-web-app-codestarnotifications" {
  name           = "${local.tags["Project"]}-chatbot"
  detail_type    = "BASIC"
  resource       = aws_codepipeline.sellix-web-app-codepipeline.arn
  status         = "ENABLED"
  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-started",
    "codepipeline-pipeline-pipeline-execution-succeeded",
    "codepipeline-pipeline-stage-execution-failed",
    "codepipeline-pipeline-action-execution-failed",
    "codepipeline-pipeline-manual-approval-succeeded",
  ]
  target {
    address = data.terraform_remote_state.sellix-web-app-chatbot-terraform-state.outputs.chatbot_arn
  }
}