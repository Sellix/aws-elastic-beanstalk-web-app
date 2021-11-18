# elastic-beanstalk-web-app

![](https://img.shields.io/badge/Sellix-AWS-orange) ![](https://img.shields.io/badge/Version-v2.0.0-blueviolet)

<p align="center">
  <img src="https://cdn.sellix.io//static/github/aws-elastic-beanstalk-infrastructure.png" alt="Sellix Web App Infrastructure Schema"/>
</p>

## Description

AWS Elastic Beanstalk infrastructure for Sellix's [web-app](https://sellix.io), in Terraform.

## Deployment

### Apply

`export ENV={environment}; envsubst < main.tf | tee main.tf`

`terraform init -backend-config="access_key=" -backend-config="secret_key="`

`terraform workspace new {environment}`

`terraform workspace select {environment}`

`terraform apply`

### Switch Workspaces

`terraform select {environment}`