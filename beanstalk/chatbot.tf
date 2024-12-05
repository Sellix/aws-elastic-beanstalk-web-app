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

resource "aws_codestarnotifications_notification_rule" "sellix-eb-codepipeline-codestarnotifications" {
  for_each    = local.slack_codepipeline_environments
  name        = "${var.tags["Project"]}-${local.aws_region}-${each.key}-codepipeline-cb"
  detail_type = "BASIC"
  resource    = aws_codepipeline.sellix-eb-codepipeline[each.key].arn
  status      = "ENABLED"

  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-started",
    "codepipeline-pipeline-pipeline-execution-succeeded",
    "codepipeline-pipeline-stage-execution-failed",
    "codepipeline-pipeline-action-execution-failed",
    "codepipeline-pipeline-manual-approval-succeeded",
  ]

  target {
    address = data.terraform_remote_state.sellix-eb-chatbot-terraform-state.outputs.chatbot-arns[local.aws_region][each.value]
  }

  depends_on = [aws_codepipeline.sellix-eb-codepipeline]
}

locals {
  slack_environments = { for envName, v in var.environments :
    envName => lookup(v, "slack_channel_names", var.slack_channel_names)
  if can(v.slack_channel_names) || var.slack_channel_names != null }

  slack_beanstalk_environments    = { for envName, v in local.slack_environments : envName => v["beanstalk"] if v["beanstalk"] != null }
  slack_codepipeline_environments = { for envName, v in local.slack_environments : envName => v["codepipeline"] if v["codepipeline"] != null }
}

// https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.eventbridge.html
resource "aws_cloudwatch_event_rule" "sellix-eb-event-rule" {
  for_each = local.slack_beanstalk_environments
  name     = "${var.tags["Project"]}-${each.key}-event-rule"
  event_pattern = jsonencode(
    {
      "source" : ["aws.elasticbeanstalk"],
      "detail-type" : [
        "Elastic Beanstalk resource status change",
        "Health status change",
        "Managed update status change"
      ],
      "detail" : {
        "EnvironmentName" : [aws_elastic_beanstalk_environment.sellix-eb-environment[each.key].name]
      },
    }
  )

  tags = merge(
    var.tags,
    {
      Name = "${var.tags["Project"]}-${each.key}-event-rule"
  })
}

resource "aws_cloudwatch_event_target" "sellix-eb-event-target" {
  for_each = aws_cloudwatch_event_rule.sellix-eb-event-rule
  rule     = each.value.name
  arn      = data.terraform_remote_state.sellix-eb-chatbot-terraform-state.outputs.chatbot-arns[local.aws_region][local.slack_beanstalk_environments[each.key]]

  input_transformer {
    input_paths = {
      "envName" : "$.detail.EnvironmentName",
      "message" : "$.detail.Message",
      "region" : "$.region",
      "severity" : "$.detail.Severity",
      "status" : "$.detail.Status",
      "account" : "$.account"
    }
    input_template = <<EOF
{
  "version": "1.0",
  "source": "custom",
  "text-type": "client-markdown",
  "content": {
    "title": "AWS ElasticBeanstalk Notification | <region> | <account>",
    "description": "*_<severity>_ - <envName>*\n><message>",
    "summary": "<status>",
    "nextSteps": [
      "<https://<region>.console.aws.amazon.com/elasticbeanstalk/home?region=<region>#/environment/dashboard?environmentName=<envName>|*AWS EB* Dashboard>"
    ]
  }
}
EOF
  }
}
