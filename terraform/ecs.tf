
####################################################
##                   E   C   S                     #
####################################################

resource "aws_ecs_cluster" "cluster" {
  name = "tf-marketboro-cluster"
}

resource "aws_ecs_service" "ecs_backend_service" {
  name                               = "tf-ecs-service"
  cluster                            = aws_ecs_cluster.cluster.id
  task_definition                    = aws_ecs_task_definition.backend.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.public_sg.id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.backend_tg.arn
    container_name   = "tf-marketboro-task"
    container_port   = 80
  }
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "tf-marketboro-task"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "tf-marketboro-task",
      "image": "${aws_ecr_repository.private_repo.repository_url}:${var.API_VERSION}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "cpu": 0,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "ap-northeast-2",
          "awslogs-stream-prefix": "app-logstream",
          "awslogs-group": "${aws_cloudwatch_log_group.markectboro_service_log_group.name}"
        }
      },
      "environment": [
        {
          "name": "DYNAMODB_TABLE_NAME",
          "value": "${aws_dynamodb_table.product.name}"
        }
      ]
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 2048
  cpu                      = 512
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn = aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_cloudwatch_log_group" "markectboro_service_log_group" {
  name = "tf-marketboro-ecs-service-loggroup"
}

#############################################
##               A   L   B                  #
#############################################
resource "aws_lb" "backend_lb" {
  name               = "tf-marketboro-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_sg.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_alb_target_group" "backend_tg" {
  name        = "tf-marketboro-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
}

resource "aws_lb_listener" "https_marketboro" {
  load_balancer_arn = aws_lb.backend_lb.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.backend_tg.arn
    type             = "forward"
  }
}