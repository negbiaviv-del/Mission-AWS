# --- מודול רשת (Networking) ---
module "networking" {
  source   = "./modules/networking"
  vpc_cidr = var.vpc_cidr
  my_ip    = var.my_ip
}

# --- מודול הרשאות (IAM) ---
module "iam" {
  source    = "./modules/iam"
  role_name = var.iam_role
}

# --- מודול שרתים (EC2 Module) ---
module "ec2_instances" {
  source            = "./modules/ec2"
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  key_name          = var.key_name

  public_subnet_id  = module.networking.public_subnet_1_id
  private_subnet_id = module.networking.public_subnet_1_id

  nginx_sg_id       = module.networking.nginx_sg_id
  backend_sg_id     = module.networking.backend_sg_id

  iam_instance_profile_name = module.iam.iam_instance_profile_name
  
  }

# --- מודול ניהול סודות (Secrets Manager) ---
module "secrets" {
  source             = "./modules/secrets"
  secret_name        = var.secret_name
  secret_description = var.secret_description
  db_password        = var.master_db_password 
}

# --- מודול מסד נתונים (RDS PostgreSQL) ---
module "rds_postgresql" {
  source = "./modules/rds_postgresql"
  
  db_sg_id   = module.networking.db_sg_id
  subnet_ids = [
    module.networking.private_subnet_1_id,
    module.networking.private_subnet_2_id
  ]
  
  db_username = "dbadmin"
  db_password = var.master_db_password
}

# --- מודול מנתב עומסים (Load Balancer) ---
module "load_balancer" {
  source = "./modules/load_balancer"
  vpc_id = module.networking.vpc_id
  subnet_ids = [
    module.networking.public_subnet_1_id,
    module.networking.public_subnet_2_id
  ]
  
  nginx_instance_id = module.ec2_instances.nginx_instance_id 
}

# --- מודולים נוספים (S3 & SNS) ---
module "s3" {
  source      = "./modules/s3_bucket"
  bucket_name = var.bucket_name
}

module "sns" {
  source      = "./modules/sns_topic"
  topic_name  = "aviv-project-alerts-v2" 
  alert_email = var.my_alert_email 
}

# --- תור הודעות (SQS) ---
resource "aws_sqs_queue" "worker_queue" {
  name = "mission-queue-v2"
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

# --- קובץ Inventory דינמי ל-Ansible ---
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"

  content = <<EOT
[frontend]
${module.ec2_instances.nginx_public_ip}

[backend]
${module.ec2_instances.backend_private_ip}

[worker]
${module.ec2_instances.worker_private_ip}

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/avivPair-01.pem

# Database Variables
rds_db_endpoint="${module.rds_postgresql.db_instance_address}"
rds_db_name="missiondb"
rds_db_user="dbadmin"
rds_db_password="${var.master_db_password}"

# AWS Services Variables 
aws_region="us-east-1"
s3_bucket_name="${module.s3.bucket_name}"
sns_topic_arn="${module.sns.topic_arn}" 
sqs_queue_url="${aws_sqs_queue.worker_queue.url}"

[backend:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q ec2-user@${module.ec2_instances.nginx_public_ip} -i ~/.ssh/avivPair-01.pem -o StrictHostKeyChecking=no"'

[worker:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q ec2-user@${module.ec2_instances.nginx_public_ip} -i ~/.ssh/avivPair-01.pem -o StrictHostKeyChecking=no"'
EOT
}