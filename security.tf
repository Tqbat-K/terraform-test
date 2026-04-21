resource "aws_security_group" "keis_alb" {
  name        = "keis-alb-sg"
  description = "Allow HTTP from internet"
  vpc_id      = aws_vpc.keis_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "keis_alb_sg"
  }
}

resource "aws_security_group" "keis_ec2" {
  name        = "keis-ec2-sg"
  description = "Allow HTTP only from ALB"
  vpc_id      = aws_vpc.keis_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.keis_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "keis_ec2_sg"
  }
}
