# elastic-beanstalk-web-app

![](https://img.shields.io/badge/Sellix-AWS-orange) ![](https://img.shields.io/badge/Version-v2.0.0-blueviolet)

<p align="center">
  <img src="https://cdn.sellix.io//static/github/aws-elastic-beanstalk-infrastructure.png" alt="Sellix Web App Infrastructure Schema"/>
</p>

## Description

AWS Elastic Beanstalk infrastructure for Sellix's [web-app](https://sellix.io), in Terraform.

## Deployment

### Apply

Initialize Environment

`export ENV={environment}`

AWS IAM (optional, see main.tf)
```
export AWS_ACCESS_KEY=""
export AWS_SECRET_KEY=""
```

Terraform Apply

```
terraform init
terraform workspace new $ENV
terraform workspace select $ENV
terraform apply
```

### Switch Workspaces

`terraform select $ENV`