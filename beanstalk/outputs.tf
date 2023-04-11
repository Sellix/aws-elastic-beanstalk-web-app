output "eb_cname" {
  value = {
    for k, v in aws_elastic_beanstalk_environment.sellix-eb-environment :
    v.name => v.cname
  }
}

output "eb_load_balancers" {
  value = {
    for _, env_name in local.envs_map :
    env_name => aws_elastic_beanstalk_environment.sellix-eb-environment[_].load_balancers
  }
}
