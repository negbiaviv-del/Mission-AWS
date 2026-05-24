# מזהה שרת ה-Nginx - חובה עבור חיבור ל-Target Group של ה-Load Balancer
output "nginx_instance_id" {
  description = "The ID of the Nginx frontend instance"
  value       = aws_instance.nginx_server.id
}

# ה-IP הציבורי של ה-Nginx - ישמש אותך כדי להתחבר אליו בדפדפן וגם עבור ה-Inventory של Ansible
output "nginx_public_ip" {
  description = "The public IP address of the Nginx frontend server"
  value       = aws_instance.nginx_server.public_ip
}

# ה-IP הפרטי של ה-Backend - חובה כדי ששרת ה-Nginx ידע לאן להעביר בקשות בתוך הרשת הפנימית
output "backend_private_ip" {
  description = "The private IP address of the Backend server"
  value       = aws_instance.backend_server.private_ip
}

# ה-IP הפרטי של ה-Worker - ישמש לניהול וקונפיגורציה פנימית
output "worker_private_ip" {
  description = "The private IP address of the Worker server"
  value       = aws_instance.worker_server.private_ip
}