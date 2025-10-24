output "service_name" { value = aws_ecs_service.svc.name }
output "task_def_arn" { value = aws_ecs_task_definition.td.arn }
