resource "aws_codepipeline" "sellix-web-app" {
  name     = "sellix-web-app"
  role_arn  = aws_iam_role.codepipeline_role.arn
  tags     = {
    "Name"        = "sellix-web-app-pipeline"
    "Project"     = "sellix-web-app"
    "Environment" = "production"
  }
  artifact_store {
    location = aws_s3_bucket.sellix-web-app-codepipeline-bucket.bucket
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
        ApplicationName = aws_elastic_beanstalk_application.sellix-web-app.name
        EnvironmentName = aws_elastic_beanstalk_environment.sellix-web-app.name
      }
    }
  }
}