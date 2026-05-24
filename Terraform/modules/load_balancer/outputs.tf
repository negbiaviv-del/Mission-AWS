output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "lb_sg_id" {
  description = "The Security Group ID of the Load Balancer"
  value       = aws_security_group.lb_sg.id
}