# 1. יצירת חומת האש עבור נתב העומסים
resource "aws_security_group" "lb_sg" {
  name        = "mission-lb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
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
}

# 2. יצירת מנתב העומסים (Application Load Balancer)
resource "aws_lb" "main" {
  name               = "mission-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = var.subnet_ids

  tags = {
    Name = "Mission-Load-Balancer"
  }
}