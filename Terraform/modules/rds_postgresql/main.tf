# 1. יצירת קבוצת הסאבנטים למסד הנתונים
resource "aws_db_subnet_group" "rds_group" {
  name       = var.db_subnet_group_name
  subnet_ids = var.subnet_ids

  tags = {
    Name = "Main-RDS-Subnet-Group"
  }
}

# 2. הקמת מסד הנתונים (PostgreSQL)
resource "aws_db_instance" "postgres" {
  allocated_storage      = var.db_storage
  engine                 = "postgres"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  
  db_subnet_group_name   = aws_db_subnet_group.rds_group.name
<<<<<<< HEAD
  vpc_security_group_ids = [var.db_sg_id] # מתחבר אוטומטית ל-Security Group התקין
  
  publicly_accessible    = false
  skip_final_snapshot    = true
=======
  vpc_security_group_ids = [var.db_sg_id] # חיבור ל-Security Group המוגן
  
  publicly_accessible    = false # השארת בסיס הנתונים פרטי (אבטחה)
  skip_final_snapshot    = true  # מאפשר מחיקה מהירה ללא Snapshots בסוף הפרויקט
>>>>>>> 8c5805a7fcb0758e843728adb23d90532e8d21dc
  
  backup_retention_period = 0 
  deletion_protection     = false

  tags = {
    Name = "Mission-PostgreSQL-Instance"
  }
}