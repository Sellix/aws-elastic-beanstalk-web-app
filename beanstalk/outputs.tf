output "eb_cname" {
  value = aws_elastic_beanstalk_environment.sellix-eb-environment.*.cname
}
