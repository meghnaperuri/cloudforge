resource "aws_ecs_cluster" "main" {
  name = local.project_name
  tags = local.common_tags
}

resource "aws_ecs_task_definition" "careerflow" {
  family                   = "${local.project_name}-careerflow-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name      = "careerflow-api"
    image     = "${aws_ecr_repository.careerflow_api.repository_url}:${var.image_tag}"
    essential = true
    portMappings = [{
      containerPort = local.api_port
      protocol      = "tcp"
    }]
    secrets = var.database_secret_arn == null ? [] : [{
      name      = "DATABASE_URL"
      valueFrom = var.database_secret_arn
    }]
    healthCheck = {
      command     = ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:${local.api_port}/health', timeout=3).close()"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 30
    }
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.careerflow.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  tags = local.common_tags
}

resource "aws_ecs_service" "careerflow" {
  name            = "careerflow-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.careerflow.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.ecs_api.id]
    assign_public_ip = true
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    precondition {
      condition     = var.desired_count == 0 || var.database_secret_arn != null
      error_message = "Set database_secret_arn before starting any CareerFlow tasks."
    }
  }

  depends_on = [
    aws_iam_role_policy.ecs_execution,
    aws_route_table_association.public_a,
    aws_route_table_association.public_b,
    aws_vpc_security_group_egress_rule.ecs_api_outbound,
  ]

  tags = local.common_tags
}
