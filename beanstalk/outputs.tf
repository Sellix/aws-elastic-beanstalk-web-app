output "eb_cname" {
  value = {for k, v in aws_elastic_beanstalk_environment.sellix-eb-environment : v.name => v.cname}
}

output "eb_load_balancers" {
  value = length(aws_elastic_beanstalk_environment.sellix-eb-environment) == length(var.environments) ? {
    for _, j in keys(var.environments) :
    j => aws_elastic_beanstalk_environment.sellix-eb-environment[_].load_balancers
  } : {}
}
