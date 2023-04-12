output "eb_cname" {
  value = {
    for _, v in aws_elastic_beanstalk_environment.sellix-eb-environment :
    v.name => v.cname
  }
}

output "eb_load_balancers" {
  value = {
    for env_name, v in aws_elastic_beanstalk_environment.sellix-eb-environment :
    env_name.value => v.load_balancers
  }
}
