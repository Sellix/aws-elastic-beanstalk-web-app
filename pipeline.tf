resource "aws_codepipeline" "web-app-codepipeline" {
  name      = "sellix-web-app-${var.environment_check}-codepipeline"
  role_arn  = aws_iam_role.web-app-codepipeline-role.arn
  tags = local.tags
  artifact_store {
    location = aws_s3_bucket.web-app-codepipeline-s3-bucket.bucket
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["sellix-web-app-artifacts"]

      configuration = {
        OAuthToken           = "${var.github_oauth}"
        Owner                = "${var.github_org}"
        Repo                 = "${var.github_repo}"
        Branch               = local.production ? "master" : "staging"
        PollForSourceChanges = true
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
      input_artifacts  = ["sellix-web-app-artifacts"]
      output_artifacts = ["sellix-web-app-codebuild-artifacts"]
      configuration = {
        ProjectName = aws_codebuild_project.web-app.name
      }
    }
  }
  stage {
    name = "Deploy"
    action {
      category         = "Deploy"
      name             = "Deploy"
      owner            = "AWS"
      provider         = "ElasticBeanstalk"
      input_artifacts  = ["sellix-web-app-codebuild-artifacts"]
      version          = "1"
      configuration = {
        ApplicationName = aws_elastic_beanstalk_application.web-app.name
        EnvironmentName = aws_elastic_beanstalk_environment.web-app-environment.name
      }
    }
  }
}

resource "aws_codebuild_project" "web-app" {
  name           = "sellix-web-app-${var.environment_check}-codebuild"
  description    = "CodeBuild"
  service_role = aws_iam_role.web-app-codebuild-role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_LARGE"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false
  }
  source {
    type = "CODEPIPELINE"
  }
  tags = local.tags
}