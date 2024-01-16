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
        ProjectName = aws_codebuild_project.sellix-eb[each.key].name
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

// https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
resource "aws_codebuild_project" "sellix-eb" {
  for_each       = local.codebuild_envs
  name           = "${var.tags["Project"]}-${each.key}-codebuild"
  description    = "CodeBuild"
  service_role   = aws_iam_role.sellix-eb-codebuild-role.arn
  encryption_key = aws_kms_key.sellix-eb-kms-key.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    modes = [contains(local.docker_environments, each.key) ? "LOCAL_DOCKER_LAYER_CACHE" : "LOCAL_SOURCE_CACHE"]
    type  = "LOCAL"
  }

  environment {
    type                        = (length(regexall("arm|aarch", each.value)) > 0 ? "ARM_CONTAINER" : "LINUX_CONTAINER")
    compute_type                = "BUILD_GENERAL1_LARGE"
    image                       = each.value
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = contains(local.docker_environments, each.key)

    dynamic "environment_variable" {
      for_each = concat(
        contains(local.docker_environments, each.key) ? [
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
          },
        ] : [],
        can(var.build_secrets[each.key]) ? [
          {
            name  = "BUILD_SECRET_ID"
            value = var.build_secrets[each.key]
          }
        ] : [],
        [for k, v in lookup(var.environments[each.key], "codebuild_vars", {}) :
        { name = k, value = v }]
      )
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
