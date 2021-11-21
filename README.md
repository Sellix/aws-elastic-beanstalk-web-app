# elastic-beanstalk-web-app

![](https://img.shields.io/badge/Sellix-AWS-orange) ![](https://img.shields.io/badge/Version-v2.0.0-blueviolet)

![infrastructure chart](https://cdn.sellix.io/static/github/aws-elastic-beanstalk-infrastructure.svg)

## Description

AWS Elastic Beanstalk infrastructure for Sellix's [web-app](https://sellix.io), in Terraform.

## Deployment

### Apply

1. Initialize Environment

`export ENV={environment}`

2. Initialize TFVARS

`mv terraform.tfvars.example.json terraform.tfvars.json`

then edit

3. Edit Providers according to desired Regions in main.tf
4. AWS IAM (optional, see main.tf)
```
export AWS_ACCESS_KEY=""
export AWS_SECRET_KEY=""
```

5. Terraform Apply

```
terraform init
terraform workspace new $ENV
terraform workspace select $ENV
terraform apply
```

### Switch Workspaces

`terraform select $ENV`