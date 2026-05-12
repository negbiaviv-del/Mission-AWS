# --- מודול רשת (Networking) ---
# יוצר את ה-VPC, ה-Subnets וחומת האש (Security Group)
module "networking" {
  source      = "./modules/networking"
  vpc_cidr    = var.vpc_cidr
  subnet_cidr = var.subnet_cidr
}

# --- מודול הרשאות (IAM) ---
module "iam_roles" {
  source    = "./modules/iam"
  role_name = var.iam_role
}

# --- משאבי EC2 (Frontend Server) ---
# השרת הראשי שעליו ירוץ ה-Nginx
resource "aws_instance" "frontend_server" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  subnet_id            = module.networking.subnet_id
  iam_instance_profile = module.iam_roles.instance_profile_name
  availability_zone    = "${var.aws_region}a"

  # חיבור חומת האש שמאפשרת SSH (22) ו-HTTP (80)
  vpc_security_group_ids = [module.networking.web_sg_id]

  tags = {
    Name = "Frontend-Server-Terraform"
  }
}

# --- מודול שרתים נוספים (EC2 Module) ---
module "ec2_instances" {
  source        = "./modules/ec2"
  ami_id        = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = module.networking.subnet_id
  web_sg_id     = module.networking.web_sg_id
}

# --- מודול ניהול סודות (Secrets Manager) ---
module "secrets" {
  source             = "./modules/secrets"
  secret_name        = var.secret_name
  secret_description = var.secret_description
}

# --- מודול מסד נתונים (RDS PostgreSQL) ---
module "rds_postgresql" {
  source = "./modules/rds_postgresql"
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

# --- מודולים נוספים (S3 & SNS) ---
module "my_s3_bucket" {
  source      = "./modules/s3_bucket"
  bucket_name = var.bucket_name
}

module "sns_notifications" {
  source     = "./modules/sns_topic"
  topic_name = var.sns_topic_name
}

# --- מאגרים לתמונות (ECR) ---
resource "aws_ecr_repository" "backend_repo" {
  name         = "mission-backend"
  force_delete = true
}

resource "aws_ecr_repository" "worker_repo" {
  name         = "mission-worker"
  force_delete = true
}