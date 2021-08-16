provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {}
}

data "terraform_remote_state" "platform" {
  backend = "s3"

  config = {
    key     = var.remote_state_key
    bucket  = var.remote_state_bucket
    region  = var.region
  }
}

data "template_file" "backend_task_definition_template" {
  template = file("backend_task_definition.json")

  vars = {
    backend_task_definition_name   = var.backend_task_definition_name
    backend_service_name           = var.backend_service_name
    backend_docker_image_url       = var.backend_docker_image_url
    memory                         = var.memory
    backend_docker_container_port  = var.backend_docker_container_port
    app_settings                   = var.app_settings
    database_url                   = var.database_url
    redis_url                      = var.redis_url
    broker_url                     = var.broker_url
    days_old_media_delete          = var.days_old_media_delete
    region                         = var.region
    worker_task_definition_name    = var.worker_task_definition_name
    db_task_definition_name        = var.db_task_definition_name
    db_docker_image_url            = var.db_docker_image_url
    db_database                    = var.db_database
    db_password                    = var.db_password
    db_user                        = var.db_user
    db_port                        = var.db_port
    redis_task_definition_name     = var.redis_task_definition_name
    redis_docker_image_url         = var.redis_docker_image_url
    redis_port                     = var.redis_port
    rabbit_task_definition_name    = var.rabbit_task_definition_name
    rabbit_docker_image_url        = var.rabbit_docker_image_url
    rabbit_user                    = var.rabbit_user
    rabbit_pass                    = var.rabbit_pass
    rabbit_port                    = var.rabbit_port

  }
}

resource "aws_ecs_task_definition" "delta-core-task-definition" {
  container_definitions     = data.template_file.backend_task_definition_template.rendered
  family                    = var.backend_service_name
  cpu                       = var.cpu
  memory                    = var.memory
  requires_compatibilities  = ["FARGATE"]
  network_mode              = "awsvpc"
  execution_role_arn        = aws_iam_role.fargate_iam_role.arn
  task_role_arn             = aws_iam_role.fargate_iam_role.arn
}

data "template_file" "frontend_task_definition_template" {
  template = file("frontend_task_definition.json")

  vars = {
    memory                         = var.memory
    region                         = var.region
    frontend_task_definition_name  = var.frontend_task_definition_name
    frontend_docker_image_url      = var.frontend_docker_image_url
    backend_internal_url           = var.backend_internal_url
    backend_public_url             = var.backend_public_url
    frontend_docker_container_port = var.frontend_docker_container_port
    frontend_service_name          = var.frontend_service_name
  }
}

resource "aws_ecs_task_definition" "delta-frontend-task-definition" {
  container_definitions     = data.template_file.frontend_task_definition_template.rendered
  family                    = var.frontend_service_name
  cpu                       = var.frontend_cpu
  memory                    = var.frontend_memory
  requires_compatibilities  = ["FARGATE"]
  network_mode              = "awsvpc"
  execution_role_arn        = aws_iam_role.fargate_iam_role.arn
  task_role_arn             = aws_iam_role.fargate_iam_role.arn
}

resource "aws_iam_role" "fargate_iam_role" {
  name = "${var.backend_service_name}-IAM-Role"

  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
 {
   "Effect": "Allow",
   "Principal": {
     "Service": ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
   },
   "Action": "sts:AssumeRole"
  }
  ]
 }
EOF
}

resource "aws_iam_role_policy" "fargate_iam_policy" {
  name = "${var.backend_service_name}-IAM-Role"
  role = aws_iam_role.fargate_iam_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:*",
        "ecr:*",
        "logs:*",
        "cloudwatch:*",
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_ecs_service" "ecs_service" {
  name            = var.backend_service_name
  task_definition = var.backend_service_name
  desired_count   = var.desired_task_number
  cluster         = data.terraform_remote_state.platform.outputs.ecs_cluster_name
  launch_type     = "FARGATE"

  network_configuration {
    # subnets           = [data.terraform_remote_state.platform.outputs.ecs_public_subnets]
    subnets           = data.terraform_remote_state.platform.outputs.ecs_public_subnets
    security_groups   = [aws_security_group.app_security_group.id]
    assign_public_ip  = true
  }

  load_balancer {
    container_name   = var.backend_task_definition_name
    container_port   = var.backend_docker_container_port
    target_group_arn = aws_alb_target_group.ecs_app_target_group.arn
  }
}

resource "aws_security_group" "app_security_group" {
  name        = "${var.backend_service_name}-SG"
  description = "Security group for delta reporter to communicate in and out"
  vpc_id      = data.terraform_remote_state.platform.outputs.vpc_id

  ingress {
    from_port   = 5000
    protocol    = "TCP"
    to_port     = 5000
    cidr_blocks = [data.terraform_remote_state.platform.outputs.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.backend_service_name}-SG"
  }
}

resource "aws_alb_target_group" "ecs_app_target_group" {
  name        = "${var.backend_service_name}-TG"
  port        = var.backend_docker_container_port
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.platform.outputs.vpc_id
  target_type = "ip"

  health_check {
    path                = "/api/v1/status"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = "60"
    timeout             = "30"
    unhealthy_threshold = "3"
    healthy_threshold   = "3"
  }

  tags = {
    Name = "${var.backend_service_name}-TG"
  }
}

resource "aws_alb_listener_rule" "ecs_alb_listener_rule" {
  listener_arn = data.terraform_remote_state.platform.outputs.ecs_alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs_app_target_group.arn
  }

  condition {
    host_header {
      values = ["${lower(var.backend_service_name)}.${data.terraform_remote_state.platform.outputs.ecs_domain_name}"]
    }
  }
}

resource "aws_ecs_service" "frontend_service" {
  name            = var.frontend_task_definition_name
  task_definition = var.frontend_service_name
  desired_count   = var.desired_task_number
  cluster         = data.terraform_remote_state.platform.outputs.ecs_cluster_name
  launch_type     = "FARGATE"

  network_configuration {
    # subnets           = [data.terraform_remote_state.platform.outputs.ecs_public_subnets]
    subnets           = data.terraform_remote_state.platform.outputs.ecs_public_subnets
    security_groups   = [aws_security_group.frontend_security_group.id]
    assign_public_ip  = true
  }

  load_balancer {
    container_name   = var.frontend_task_definition_name
    container_port   = var.frontend_docker_container_port
    target_group_arn = aws_alb_target_group.ecs_frontend_target_group.arn
  }
}

resource "aws_security_group" "frontend_security_group" {
  name        = "${var.frontend_task_definition_name}-SG"
  description = "Security group for delta reporter to communicate in and out"
  vpc_id      = data.terraform_remote_state.platform.outputs.vpc_id

  ingress {
    from_port   = 3000
    protocol    = "TCP"
    to_port     = 3000
    cidr_blocks = [data.terraform_remote_state.platform.outputs.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.frontend_task_definition_name}-SG"
  }
}

resource "aws_alb_target_group" "ecs_frontend_target_group" {
  name        = "${var.frontend_task_definition_name}-TG"
  port        = var.frontend_docker_container_port
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.platform.outputs.vpc_id
  target_type = "ip"

  health_check {
    path                = "/api/healthcheck"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = "300"
    timeout             = "120"
    unhealthy_threshold = "5"
    healthy_threshold   = "5"
  }

  tags = {
    Name = "${var.frontend_task_definition_name}-TG"
  }
}

resource "aws_alb_listener_rule" "ecs_alb_frontend_listener_rule" {
  listener_arn = data.terraform_remote_state.platform.outputs.ecs_alb_listener_arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs_frontend_target_group.arn
  }

  condition {
    host_header {
      values = ["${lower(var.frontend_service_name)}.${data.terraform_remote_state.platform.outputs.ecs_domain_name}"]
    }
  }
}

resource "aws_cloudwatch_log_group" "delta_backend_log_group" {
  name = "${var.backend_task_definition_name}-LogGroup"
}

resource "aws_cloudwatch_log_group" "delta_frontend_log_group" {
  name = "${var.frontend_task_definition_name}-LogGroup"
}

resource "aws_cloudwatch_log_group" "delta_db_log_group" {
  name = "delta-db-LogGroup"
}

resource "aws_cloudwatch_log_group" "delta_rabbit_log_group" {
  name = "delta-rabbit-LogGroup"
}

resource "aws_cloudwatch_log_group" "delta_redis_log_group" {
  name = "delta-redis-LogGroup"
}

resource "aws_cloudwatch_log_group" "delta_worker_log_group" {
  name = "delta-worker-LogGroup"
}
