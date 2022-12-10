data "terraform_remote_state" "sellix-eb-chatbot-terraform-state" {
  backend = "s3"
  config = {
    bucket     = "sellix-deployments"
    key        = "aws-chatbot.tfstate"
    region     = "eu-west-1"
    profile    = "sellix-terraform"
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
  }
}

resource "aws_codestarnotifications_notification_rule" "sellix-eb-codestarnotifications" {
  count       = length(var.environments)
  name        = "${var.tags["Project"]}-${local.aws_region}-${keys(var.environments)[count.index]}-chatbot"
  detail_type = "BASIC"
  resource    = aws_codepipeline.sellix-eb-codepipeline[count.index].arn
  status      = "ENABLED"
  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-started",
    "codepipeline-pipeline-pipeline-execution-succeeded",
    "codepipeline-pipeline-stage-execution-failed",
    "codepipeline-pipeline-action-execution-failed",
    "codepipeline-pipeline-manual-approval-succeeded",
  ]
  target {
    address = data.terraform_remote_state.sellix-eb-chatbot-terraform-state.outputs["${local.aws_region}_chatbot-arn"]
  }
}
