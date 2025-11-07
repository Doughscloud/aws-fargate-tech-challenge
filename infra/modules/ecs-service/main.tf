terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_region" "current" {}

resource "aws_iam_role" "task_exec" {
  name = "${var.service_name}-exec"
  assume_role_policy = jsonencode({ Version="2012-10-17", Statement=[{Effect="Allow",Principal={Service="ecs-tasks.amazonaws.com"},Action="sts:AssumeRole"}] })
  tags = var.tags
}
resource "aws_iam_role_policy_attachment" "task_exec" {
  role = aws_iam_role.task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task_role" {
  name = "${var.service_name}-task"
  assume_role_policy = jsonencode({ Version="2012-10-17", Statement=[{Effect="Allow",Principal={Service="ecs-tasks.amazonaws.com"},Action="sts:AssumeRole"}] })
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "lg" {
  name              = var.log_group_name != null ? var.log_group_name : "/ecs/${var.service_name}"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_ecs_task_definition" "td" {
  family                   = var.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_exec.arn
  task_role_arn            = aws_iam_role.task_role.arn
  container_definitions = jsonencode([
    {
      name  = var.service_name,
      image = var.container_image,
      essential = true,
      portMappings = [{ containerPort = var.container_port, protocol = "tcp" }],
      environment = [for k,v in var.env_vars : { name = k, value = v }],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-region        = data.aws_region.current.name,
          awslogs-group         = aws_cloudwatch_log_group.lg.name,
          awslogs-stream-prefix = var.service_name
        }
      }
    }
  ])
  tags = var.tags
}

resource "aws_ecs_service" "svc" {
  name            = var.service_name
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.td.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.use_alb ? [1] : []
    content {
      target_group_arn = var.tg_arn
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }

  dynamic "service_registries" {
    for_each = var.use_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.this[0].arn
    }
  }

  tags = var.tags
}

resource "aws_service_discovery_service" "this" {
  count = var.use_service_discovery ? 1 : 0
  name  = var.dns_name
  dns_config {
    namespace_id = var.namespace_id
    dns_records {
      ttl  = 5
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
  tags = var.tags
}

resource "aws_appautoscaling_target" "asg" {
  max_capacity       = var.max_count
  min_capacity       = var.min_count
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.svc.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
resource "aws_appautoscaling_policy" "cpu" {
  name        = "${var.service_name}-cpu-50"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.asg.resource_id
  scalable_dimension = aws_appautoscaling_target.asg.scalable_dimension
  service_namespace  = aws_appautoscaling_target.asg.service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = 50
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}
