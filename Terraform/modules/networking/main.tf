# 1. יצירת ה-VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "main-vpc" }
}

# 2. Internet Gateway - מאפשר יציאה לאינטרנט בחינם
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main-igw" }
}

# 3. טבלת ניתוב ציבורית (Public Route Table)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = { Name = "public-route-table" }
}

# 4. סאבנטים ציבוריים (עבור Nginx וגם עבור ה-Backend - כדי לחסוך NAT Gateway)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "public-subnet-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "public-subnet-2" }
}

# חיבור הסאבנטים הציבוריים לטבלה הציבורית
resource "aws_route_table_association" "pub1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "pub2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# 5. סאבנטים פרטיים (עבור ה-RDS - מוגנים לגמרי)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = "us-east-1a"
  tags              = { Name = "private-db-subnet-1" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = "us-east-1b"
  tags              = { Name = "private-db-subnet-2" }
}

# 6. DB Subnet Group - חובה עבור יצירת RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "main-rds-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  tags       = { Name = "Main DB Subnet Group" }
}

# 7. Security Groups - האבטחה הלוגית
# ---------------------------------------------------------

# שומר עבור ה-Nginx (פתוח לעולם בפורט 80)
resource "aws_security_group" "nginx_sg" {
  name   = "nginx-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # רק אתה יכול להתחבר
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# שומר עבור ה-Backend (פתוח רק ל-Nginx)
resource "aws_security_group" "backend_sg" {
  name   = "backend-sg"
  vpc_id = aws_vpc.main.id

  # גישה לאפליקציה מה-Nginx
  ingress {
    from_port       = 5000 
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_sg.id] 
  }

  # התיקון: גישת SSH מתאפשרת אך ורק משרת ה-Nginx (הבאסטיון שלנו)
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_sg.id] # מחליפים את ה-cidr_blocks בזה
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# שומר עבור ה-RDS (פתוח רק ל-Backend)
resource "aws_security_group" "db_sg" {
  name   = "rds-db-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id] # גישה רק מה-Backend!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}