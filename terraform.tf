terraform {
  required_version = ">= 0.12.5"
}

provider "aws" {
  version = "~> 2.70"
  region  = "ap-northeast-1"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_lb" "keis_alb" {
  name               = "keis-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.keis_alb.id]
  subnets            = [aws_subnet.keis_subnet_1.id, aws_subnet.keis_subnet_2.id]

  tags = {
    Name = "keis-alb"
  }
}

resource "aws_lb_target_group" "keis_tg" {
  name     = "keis-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.keis_vpc.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
    path                = "/"
    matcher             = "200-399"
  }

  tags = {
    Name = "keis-target-group"
  }
}

resource "aws_lb_listener" "keis_http" {
  load_balancer_arn = aws_lb.keis_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No matching rule"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "keis_forward" {
  listener_arn = aws_lb_listener.keis_http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.keis_tg.arn
  }

  condition {
    field  = "path-pattern"
    values = ["/*"]
  }
}

resource "aws_instance" "keis_ec2" {
  count = 2

  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  subnet_id              = element([aws_subnet.keis_subnet_1.id, aws_subnet.keis_subnet_2.id], count.index)
  vpc_security_group_ids = [aws_security_group.keis_ec2.id]

  user_data = <<-EOF_USER_DATA
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl enable httpd
              echo "Hello from keis instance $(hostname)" > /var/www/html/index.html
              systemctl start httpd
              EOF_USER_DATA

  tags = {
    Name = "keis-ec2-${count.index + 1}"
  }
}

resource "aws_lb_target_group_attachment" "keis_attach" {
  count = length(aws_instance.keis_ec2)

  target_group_arn = aws_lb_target_group.keis_tg.arn
  target_id = aws_instance.keis_ec2[count.index].id
  port = 80
}

resource "aws_cloudwatch_metric_alarm" "keis_ec2_high_cpu" {
  count = length(aws_instance.keis_ec2)

  alarm_name = "keis-ec2-${count.index + 1}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 300
  statistic = "Average"
  threshold = 80
  alarm_description = "EC2 CPU utilization is over 80%"
  treat_missing_data = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.keis_ec2[count.index].id
  }
}

resource "aws_cloudwatch_metric_alarm" "keis_alb_5xx" {
  alarm_name = "keis-alb-5xx"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 1
  metric_name = "HTTPCode_ELB_5XX_Count"
  namespace = "AWS/ApplicationELB"
  period = 60
  statistic = "Sum"
  threshold = 1
  alarm_description = "ALB returned 5xx responses"
  treat_missing_data = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.keis_alb.arn_suffix
  }
}

output "alb_dns_name" {
  value = aws_lb.keis_alb.dns_name
}

output "ec2_instance_ids" {
  value = aws_instance.keis_ec2[*].id
}
