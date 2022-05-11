resource "aws_codepipeline" "sellix-eb-codepipeline" {
  count = length(var.github_opts.repo)
  name     = "${local.tags["Project"]}-${var.github_opts.repo[count.index]}-codepipeline"
  role_arn = aws_iam_role.sellix-eb-codepipeline-role.arn
  tags = merge({
    "Name" = "${local.tags["Project"]}-codepipeline"
    },
    local.tags
  )
  artifact_store {
    location = aws_s3_bucket.sellix-eb-codepipeline-s3-bucket.bucket
    type     = "S3"
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
        FullRepositoryId     = "${var.github_opts["org"]}/${var.github_opts.repo[count.index]}"
        BranchName           = var.github_opts["branch"]
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
        ProjectName = aws_codebuild_project.sellix-eb.name
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
        EnvironmentName = aws_elastic_beanstalk_environment.sellix-eb-environment[count.index].name
      }
    }
  }
}

resource "aws_codebuild_project" "sellix-eb" {
  name         = "${local.tags["Project"]}-codebuild"
  description  = "CodeBuild"
  service_role = aws_iam_role.sellix-eb-codebuild-role.arn
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
    image                       = "aws/codebuild/standard:5.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false
  }
  source {
    type = "CODEPIPELINE"
  }
  tags = merge({
    "Name" = "${local.tags["Project"]}-codebuild-project"
    },
    local.tags
  )
}
