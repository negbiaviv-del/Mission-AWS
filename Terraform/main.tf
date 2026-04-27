# --- משאבי EC2 (Legacy/Frontend) ---
resource "aws_instance" "frontend_server" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  subnet_id            = module.networking.subnet_id
  iam_instance_profile = module.iam_roles.instance_profile_name
  availability_zone    = "${var.aws_region}a"

  tags = {
    Name = "Frontend-Server-Terraform"
  }
}

# --- מודול אחסון (S3) ---
module "my_s3_bucket" {
  source      = "./modules/s3_bucket"
  bucket_name = "aviv-mission-aws-bucket-1997"
}

# --- מודול רשת (Networking) ---
module "networking" {
  source      = "./modules/networking"
  vpc_cidr    = "10.0.0.0/16"
  subnet_cidr = "10.0.1.0/24"
}

# --- מודול שרתים (EC2 Module) ---
module "ec2_instances" {
  source    = "./modules/ec2"
  subnet_id = module.networking.subnet_id
}

# --- מודול התראות (SNS) ---
module "sns_notifications" {
  source     = "./modules/sns_topic"
  topic_name = "aviv-project-alerts"
}

# --- מודול הרשאות (IAM) ---
module "iam_roles" {
  source    = "./modules/iam"
  role_name = "aviv-mission-iam-role"
}

# --- מודול מסד נתונים (RDS PostgreSQL) ---
module "rds_postgresql" {
  source = "./modules/rds_postgresql"

  # שימוש בשתי תתי-הרשתות עבור High Availability
  subnet_ids = [
    module.networking.subnet_id,
    module.networking.subnet2_id
  ]
}

# --- מודול מנתב עומסים (Load Balancer) ---
module "load_balancer" {
  source = "./modules/load_balancer"

  vpc_id = module.networking.vpc_id
  subnet_ids = [
    module.networking.subnet_id,
    module.networking.subnet2_id
  ]
}

# --- מודול ניהול סודות (Secrets Manager) ---
module "secrets" {
  source             = "./modules/secrets"
  secret_name        = "aviv-db-pass-unique-123"
  secret_description = "Password for my PostgreSQL RDS"
}