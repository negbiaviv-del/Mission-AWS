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

# 2. יצירת מנתב העומסים (ALB)
resource "aws_lb" "main" {
  name               = "mission-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = var.subnet_ids # כאן נכניס את ה-Public Subnets

  tags = {
    Name = "Mission-Load-Balancer"
  }
}

# 3. הוספה: Target Group - הקבוצה שתכיל את שרת ה-Nginx שלנו
resource "aws_lb_target_group" "frontend_tg" {
  name     = "mission-frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # הגדרות בדיקת בריאות (Health Check) - ה-LB מוודא שהשרת חי לפני שהוא מעביר אליו לקוחות
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# 4. הוספה: Listener - מאזין בפורט 80 ומעביר ל-Target Group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

# 5. הוספה: שיוך שרת ה-Nginx ל-Target Group
resource "aws_lb_target_group_attachment" "nginx_attach" {
  target_group_arn = aws_lb_target_group.frontend_tg.arn
  target_id        = var.nginx_instance_id # נצטרך לקבל את ה-ID של השרת ממודול ה-EC2
  port             = 80
}