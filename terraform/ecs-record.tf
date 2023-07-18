
####################################################
##                   E   C   S                     #
####################################################

resource "aws_ecs_cluster" "simple_cluster" {
  name = "tf-simple-cluster"
}

resource "aws_ecs_service" "ecs_simple_service" {
  name                               = "tf-ecs-service"
  cluster                            = aws_ecs_cluster.simple_cluster.id
  task_definition                    = aws_ecs_task_definition.record_task.arn
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
    target_group_arn = aws_alb_target_group.ecs_record_target_group.arn
    container_name   = "tf-simple-task"
    container_port   = 80
  }
}

resource "aws_ecs_task_definition" "record_task" {
  family                   = "tf-simple-task"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "tf-simple-task",
      "image": "${var.ECR_IMAGE_URL}",
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
          "awslogs-group": "${aws_cloudwatch_log_group.ecs_record_service_log_group.name}"
        }
      },
      "environment": [
        {
          "name": "ACCESS_KEY_ID",
          "value": "${var.ACCESS_KEY_ID}"
        },
        {
          "name": "SECRET_ACCESS_KEY",
          "value": "${var.SECRET_KEY}"
        },
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

resource "aws_cloudwatch_log_group" "ecs_record_service_log_group" {
  name = "tf-record-ecs-service-loggroup"
}

#############################################
##               A   L   B                  #
#############################################
resource "aws_lb" "record_lb" {
  name               = "tf-record-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_sg.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_alb_target_group" "ecs_record_target_group" {
  name        = "tf-record-tg"
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

resource "aws_alb_listener" "http_record" {
  load_balancer_arn = aws_lb.record_lb.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.ecs_record_target_group.id
    type             = "forward"
  }
}
