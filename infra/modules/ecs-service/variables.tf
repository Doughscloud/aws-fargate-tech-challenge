variable "service_name" {}
variable "cluster_name" {}
variable "container_image" {}
variable "container_port" {}
variable "cpu" { default = 512 }
variable "memory" { default = 1024 }
variable "desired_count" { default = 1 }
variable "min_count" { default = 1 }
variable "max_count" { default = 4 }
variable "assign_public_ip" { default = false }
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "use_alb" { default = false }
variable "tg_arn" { default = null }
variable "use_service_discovery" { default = false }
variable "namespace_id" { default = null }
variable "dns_name" { default = null }
variable "env_vars" { type = map(string) default = {} }
variable "log_group_name" { default = null }
variable "tags" { type = map(string) default = {} }
