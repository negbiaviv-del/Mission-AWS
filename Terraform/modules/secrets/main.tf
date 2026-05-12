resource "aws_secretsmanager_secret" "db_password" {
  name                    = var.secret_name
  description             = var.secret_description
  
  # --- שורת הקסם שמונעת את הבעיה לתמיד ---
  recovery_window_in_days = 0 
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = "MySuperSecretPassword2026!" 
}

