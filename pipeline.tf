resource "aws_codepipeline" "web-app-codepipeline" {
  name      = "sellix-web-app-codepipeline"
  role_arn  = aws_iam_role.web-app-codepipeline-role.arn
  tags     = {
    "Name"        = "sellix-web-app-codepipeline"
    "Project"     = "sellix-web-app"
    "Environment" = "production"
  }
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
      output_artifacts = ["sellix-web-app-Artifacts"]

      configuration = {
        OAuthToken           = "${var.github_oauth}"
        Owner                = "${var.github_org}"
        Repo                 = "${var.github_repo}"
        Branch               = "master"
        PollForSourceChanges = true
      }
    }
  }
  stage {
    name = "Deploy"
    action {
      category = "Deploy"
      name = "Deploy"
      owner = "AWS"
      provider = "ElasticBeanstalk"
      input_artifacts = ["sellix-web-app-Artifacts"]
      version          = "1"
      configuration = {
        ApplicationName = aws_elastic_beanstalk_application.web-app.name
        EnvironmentName = aws_elastic_beanstalk_environment.web-app-environment.name
      }
    }
  }
}