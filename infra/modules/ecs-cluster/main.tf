terraform { required_providers { aws = { source = "hashicorp/aws" version = ">= 5.0" } } }

resource "aws_ecs_cluster" "this" {
  name = var.name
  setting { name = "containerInsights" value = "enabled" }
  tags = merge(var.tags, { Name = var.name })
}

resource "aws_service_discovery_private_dns_namespace" "ns" {
  name = "local"
  vpc  = var.vpc_id
  tags = merge(var.tags, { Name = "${var.name}-sd-namespace" })
}
