# 1. יצירת ה-VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "main-vpc" }
}

# 2. שער אינטרנט (החלק שמאפשר יציאה החוצה)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main-igw" }
}

# 3. טבלת ניתוב (ה"כביש" לאינטרנט)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = { Name = "public-route-table" }
}

# 4. חיבור ה-Subnet לטבלת הניתוב (חובה!)
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.public.id
}

# 5. הסאבנט עצמו
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true # דואג שהשרת יקבל IP ציבורי
  tags                    = { Name = "main-subnet" }
}

# 6. ה-Security Group (השומר שראינו בצילום מסך)
resource "aws_security_group" "web_sg" {
  name   = "web_access_sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
}

# 7. הסאבנט השני (חובה עבור RDS ו-Load Balancer)
resource "aws_subnet" "second" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet2_cidr
  availability_zone       = "us-east-1b" # שים לב שזה b ולא a
  map_public_ip_on_launch = true

  tags = { Name = "second-subnet" }
}

# 8. חיבור הסאבנט השני לטבלת הניתוב (כדי שגם לו יהיה אינטרנט)
resource "aws_route_table_association" "second_assoc" {
  subnet_id      = aws_subnet.second.id
  route_table_id = aws_route_table.public.id
}