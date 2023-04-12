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
        FullRepositoryId     = each.value["github"]["repo"]
        BranchName           = each.value["github"]["branch"]
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
        ProjectName = aws_codebuild_project.sellix-eb[each.value["versions"]["codebuild"]].name
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
  for_each       = toset(local.codebuild_envs)
  name           = "${var.tags["Project"]}-codebuild-${each.key}"
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
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_LARGE"
    image                       = "aws/codebuild/standard:${each.key}.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false
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
