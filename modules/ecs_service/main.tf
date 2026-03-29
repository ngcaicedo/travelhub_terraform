resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.project_name}-${var.environment}/${var.service_name}"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-${var.environment}-${var.service_name}"
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project_name}-${var.environment}-${var.service_name}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([{
    name      = var.service_name
    image     = var.ecr_image_url
    essential = true

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = var.environment_variables
    secrets     = var.secrets

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.this.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name = "${var.project_name}-${var.environment}-${var.service_name}"
  }
}

resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-${var.environment}-${var.service_name}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.service_name
    container_port   = var.container_port
  }

  health_check_grace_period_seconds = 60

  tags = {
    Name = "${var.project_name}-${var.environment}-${var.service_name}"
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}
