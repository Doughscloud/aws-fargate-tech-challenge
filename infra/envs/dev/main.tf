terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
provider "aws" { region = var.aws_region }

locals {
  tags = { project = var.project_name, env = var.env }
  name = "${var.project_name}-${var.env}"
}

module "vpc" {
  source   = "../../modules/vpc"
  name     = local.name
  cidr     = var.cidr
  az_count = 2
  tags     = local.tags
}

module "ecr" {
  source      = "../../modules/ecr"
  name_prefix = local.name
  tags        = local.tags
}

module "ecs_cluster" {
  source = "../../modules/ecs-cluster"
  name   = "${local.name}-cluster"
  vpc_id = module.vpc.vpc_id
  tags   = local.tags
}

module "alb" {
  source     = "../../modules/alb"
  name       = local.name
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  tags       = local.tags
}

resource "aws_security_group" "frontend" {
  name   = "${local.name}-frontend-sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    description     = "From ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [module.alb.alb_sg_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

resource "aws_security_group" "backend" {
  name   = "${local.name}-backend-sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    description     = "From frontend"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

module "frontend_service" {
  source                 = "../../modules/ecs-service"
  service_name           = "${local.name}-frontend"
  cluster_name           = module.ecs_cluster.cluster_name
  container_image        = "${module.ecr.frontend_url}:latest"
  container_port         = 80
  cpu                    = 512
  memory                 = 1024
  desired_count          = 1
  min_count              = 1
  max_count              = 4
  assign_public_ip       = false
  subnet_ids             = module.vpc.private_subnet_ids
  security_group_ids     = [aws_security_group.frontend.id]
  use_alb                = true
  tg_arn                 = module.alb.tg_arn
  env_vars = {
    REACT_APP_API_URL = "http://backend.local:8080"
  }
  log_group_name = "/ecs/${local.name}-frontend"
  tags           = local.tags
}

module "backend_service" {
  source                 = "../../modules/ecs-service"
  service_name           = "${local.name}-backend"
  cluster_name           = module.ecs_cluster.cluster_name
  container_image        = "${module.ecr.backend_url}:latest"
  container_port         = 8080
  cpu                    = 512
  memory                 = 1024
  desired_count          = 1
  min_count              = 1
  max_count              = 4
  assign_public_ip       = false
  subnet_ids             = module.vpc.private_subnet_ids
  security_group_ids     = [aws_security_group.backend.id]
  use_alb                = false
  use_service_discovery  = true
  namespace_id           = module.ecs_cluster.namespace_id
  dns_name               = "backend"
  env_vars = {
    PORT                = "8080"
    CORS_ALLOWED_ORIGIN = "http://${module.alb.alb_dns_name}"
  }
  log_group_name = "/ecs/${local.name}-backend"
  tags           = local.tags
}
