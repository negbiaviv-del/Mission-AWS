# 1. הגדרת קבוצת הרשתות למסד הנתונים
resource "aws_db_subnet_group" "default" {
  name       = "main-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "My DB subnet group"
  }
}

# 2. הקמת מסד הנתונים (PostgreSQL)
resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "16.3" # גרסת פוסטגרס יציבה ונפוצה
  instance_class       = "db.t3.micro"
  db_name              = "missiondb"
  username             = "dbadmin"
  password             = "MissionPassword123!" # בסביבת פרודקשן משתמשים ב-Secrets Manager, אבל למעבדה זה בסדר
  db_subnet_group_name = aws_db_subnet_group.default.name
  skip_final_snapshot  = true
  publicly_accessible  = false # השארנו אותו פרטי לאבטחה מירבית

  tags = {
    Name = "Mission-PostgreSQL"
  }
}