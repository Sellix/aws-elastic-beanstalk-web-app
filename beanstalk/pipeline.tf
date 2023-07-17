resource "aws_codepipeline" "sellix-eb-codepipeline" {
  for_each = var.environments
  name     = "${var.tags["Project"]}-${each.key}-codepipeline"
  role_arn = aws_iam_role.sellix-eb-codepipeline-role.arn
  artifact_store {
    location = aws_s3_bucket.sellix-eb-codepipeline-s3-bucket.bucket
    type     = "S3"
    encryption_key {
      id   = aws_kms_key.sellix-eb-kms-key.arn
      type = "KMS"
    }
  }
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["sellix-eb-artifacts"]
      configuration = {
        ConnectionArn        = var.codestar_connection_arn
        FullRepositoryId     = can(each.value["github"]["repo"]) ? each.value["github"]["repo"] : ""
        BranchName           = can(each.value["github"]["branch"]) ? each.value["github"]["branch"] : ""
        DetectChanges        = !var.is_production
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["sellix-eb-artifacts"]
      output_artifacts = ["sellix-eb-codebuild-artifacts"]
      configuration = {
        ProjectName = aws_codebuild_project.sellix-eb[contains(
          keys(local.docker_environments),
          each.key) ? each.key :
          can(each.value.versions.codebuild) ?
          each.value.versions.codebuild : var.default_codebuild_image
        ].name
      }
    }
  }
  stage {
    name = "Deploy"
    action {
      category        = "Deploy"
      name            = "Deploy"
      owner           = "AWS"
      provider        = "ElasticBeanstalk"
      input_artifacts = ["sellix-eb-codebuild-artifacts"]
      version         = "1"
      configuration = {
        ApplicationName = aws_elastic_beanstalk_application.sellix-eb.name
        EnvironmentName = aws_elastic_beanstalk_environment.sellix-eb-environment[each.key].name
      }
    }
  }
  tags = merge({
    "Name" = "${var.tags["Project"]}-codepipeline"
    },
    var.tags
  )
}

resource "aws_codebuild_project" "sellix-eb" {
  for_each       = local.codebuild_envs
  name           = "${var.tags["Project"]}-${contains(keys(local.docker_environments), each.key)
  ? each.key : substr(each.key, -3, -1)}-codebuild"
  description    = "CodeBuild"
  service_role   = aws_iam_role.sellix-eb-codebuild-role.arn
  encryption_key = aws_kms_key.sellix-eb-kms-key.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  cache {
    modes = ["LOCAL_SOURCE_CACHE"]
    type  = "LOCAL"
  }
  environment {
    type = (length(
      regexall("arm|aarch",
        lookup(local.docker_environments, each.key, each.key)
      )
    ) > 0 ? "ARM_CONTAINER" : "LINUX_CONTAINER")
    compute_type                = "BUILD_GENERAL1_LARGE"
    image                       = lookup(local.docker_environments, each.key, each.key)
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = contains(keys(local.docker_environments), each.key)

    dynamic "environment_variable" {
      for_each = contains(keys(local.docker_environments), each.key) ? [
        {
          name  = "AWS_REGION"
          value = local.aws_region
        },
        {
          name  = "AWS_ACCOUNT_ID"
          value = local.aws_account_id
        },
        {
          name = "IMAGE_REPO_NAME"
          value = reverse(split("/",
            (contains(keys(aws_ecr_repository.sellix-ecr), each.key) ?
            aws_ecr_repository.sellix-ecr[each.key].repository_url : "")
          ))[0]
        }
      ] : []
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
      }
    }
  }
  source {
    type = "CODEPIPELINE"
  }
  tags = merge({
    "Name" = "${var.tags["Project"]}-codebuild-project"
    },
    var.tags
  )
}
