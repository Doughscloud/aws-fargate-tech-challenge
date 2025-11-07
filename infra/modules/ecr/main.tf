terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_ecr_repository" "frontend" {
  name = "${var.name_prefix}-frontend"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = merge(var.tags, { Name = "${var.name_prefix}-frontend" })
}

resource "aws_ecr_repository" "backend" {
  name = "${var.name_prefix}-backend"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = merge(var.tags, { Name = "${var.name_prefix}-backend" })
}
