# DevOps Tech Challenge 1 – ECS Fargate (Option A: Service Discovery)

This repo deploys a React frontend (public via ALB) and an Express backend (private via ECS Service Discovery) on AWS ECS Fargate using Terraform, with Jenkins CI/CD to build/push images to ECR and update ECS services.

## How to Deploy (Dev)

1) Terraform (creates VPC, ALB, ECS, ECR, Cloud Map):
```bash
cd infra/envs/dev
terraform init
terraform apply -auto-approve
Note the outputs:

frontend_alb_dns

service_discovery_namespace (should be local)

Jenkins job parameters / credentials to set:

aws-ecr-registry (Secret text): <acct>.dkr.ecr.us-east-1.amazonaws.com

ecs-cluster-name (Secret text): from Terraform output

frontend-service-name (Secret text): devops-tech-challenge1-dev-frontend

backend-service-name (Secret text): devops-tech-challenge1-dev-backend

frontend-exec-role-arn, frontend-task-role-arn, backend-exec-role-arn, backend-task-role-arn

Set env: FRONTEND_ALB_DNS=<value from terraform>

Set env: CORS_ALLOWED_ORIGIN=http://<FRONTEND_ALB_DNS>

Run Jenkins pipeline:

Builds Docker images, pushes to ECR, updates ECS services.

Verify:

Open http://<FRONTEND_ALB_DNS> — you should see SUCCESS with a GUID.
```
