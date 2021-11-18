resource "aws_codestarconnections_connection" "sellix-web-app-github-connection" {
  name          = "sellix-web-app-${terraform.workspace}-github-connection"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "sellix-web-app-codepipeline" {
  name      = "sellix-web-app-${terraform.workspace}-codepipeline"
  role_arn  = aws_iam_role.sellix-web-app-codepipeline-role.arn
  tags = {
    "Name"  = "sellix-web-app-${terraform.workspace}-codepipeline"
    "Project"     = "sellix-web-app-${terraform.workspace}"
    "Environment" = terraform.workspace
  }
  artifact_store {
    location = aws_s3_bucket.sellix-web-app-codepipeline-s3-bucket.bucket
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
      output_artifacts = ["sellix-web-app-artifacts"]

      configuration = {
        ConnectionArn         = aws_codestarconnections_connection.sellix-web-app-github-connection.arn
        FullRepositoryId      = "${var.github_org}/${var.github_repo}"
        BranchName            = "development"
        PollForSourceChanges  = false
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
        ProjectName = aws_codebuild_project.sellix-web-app.name
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
        ApplicationName = aws_elastic_beanstalk_application.sellix-web-app.name
        EnvironmentName = aws_elastic_beanstalk_environment.sellix-web-app-environment.name
      }
    }
  }
}

resource "aws_codebuild_project" "sellix-web-app" {
  name           = "sellix-web-app-${terraform.workspace}-codebuild"
  description    = "CodeBuild"
  service_role = aws_iam_role.sellix-web-app-codebuild-role.arn
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
  tags = {
    "Name"  = "sellix-web-app-${terraform.workspace}-codebuild-project"
    "Project"     = "sellix-web-app-${terraform.workspace}"
    "Environment" = terraform.workspace
  }
}