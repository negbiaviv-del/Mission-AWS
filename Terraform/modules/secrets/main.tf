# יצירת ה"כספת" בעזרת המשתנים
resource "aws_secretsmanager_secret" "db_password" {
  name        = var.secret_name
  description = var.secret_description
}

# הכנסת הערך לתוך הכספת
resource "aws_secretsmanager_secret_version" "db_password_val" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = "MySuperSecretPassword2026!"
}