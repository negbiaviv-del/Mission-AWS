# 1. יצירת ה-VPC (הרשת הווירטואלית)
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# 2. יצירת Internet Gateway (היציאה לאינטרנט)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main-igw"
  }
}

# 3. יצירת תת-רשת (Subnet)
resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.subnet_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true # זה מה שייתן לשרתים שלך IP פומבי!

  tags = {
    Name = "main-subnet"
  }
}

# 4. יצירת תת-רשת שנייה (לאזורים מרובים)
resource "aws_subnet" "second_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.subnet2_cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "second-subnet"
  }
}