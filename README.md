# aws-terraform-demo

Below are some information for each folder inside this repo.

## k8-manifests

Contains the manifest file(s) for node-app that runs inside the kubernetes cluster.

## node-app

Contains Javascript, Dockerfile and docker-compose files that are used to run the app either in a raw instance or inside a container.

## terraform-gitea

Terraform config files to provision a gitea-EC2-instance, a target group that points to the instance and AWS Application load balancer to expose the service to public.

The gitea service can be accessed here: https://gitea.syahmiahmad.studio/

## terraform-k8

Terraform config files to provision kubernetes cluster inside Azure AKS.
