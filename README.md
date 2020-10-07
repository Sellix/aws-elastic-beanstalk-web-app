# elastic-beanstalk-web-app

## Description

Repo related to the infrastructure with AWS Elastic Beanstalk for our web-app

## Setup

Replace `{environment}` with either `production` or `staging`

`export ENV={environment}; envsubst < main.tf | tee main.tf`
`terraform init -backend-config="access_key=" -backend-config="secret_key=" -backend-config="env={environment}"`

`terraform apply`

## Branches

- `master`: production beanstalk.

- `staging`: staging beanstalk, needs less resources and ec2 than `master`.

- `legacy`: branch for the old web app for test purposes, follows `staging`'s requirements.