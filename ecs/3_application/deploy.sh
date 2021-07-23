#!/bin/sh

REGION="eu-west-1"
SERVICE_NAME="delta-reporter"

if [ "$1" = "plan" ];then
    terraform init -backend-config="app-prod.config"
    terraform plan -var-file="production.tfvars" -var "backend_docker_image_url=deltareporter/delta_core"
elif [ "$1" = "deploy" ];then
    terraform init -backend-config="app-prod.config"
    terraform apply -var-file="production.tfvars" -var "backend_docker_image_url=deltareporter/delta_core" -auto-approve
elif [ "$1" = "destroy" ];then
    terraform init -backend-config="app-prod.config"
    terraform destroy -var-file="production.tfvars" -var "backend_docker_image_url=deltareporter/delta_core" -auto-approve
fi
