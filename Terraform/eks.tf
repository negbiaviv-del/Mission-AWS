module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "aviv-mission-cluster"
  cluster_version = "1.31" # הגרסה היציבה והמומלצת כרגע

  # --- החיבור לרשת שלך ---
  vpc_id = module.networking.vpc_id
  subnet_ids = [
    module.networking.private_subnet_1_id,
    module.networking.private_subnet_2_id
  ]

  # מאפשר לך להריץ פקודות kubectl מהטרמינל שלך
  cluster_endpoint_public_access = true

  # הגדרת השרתים שיריצו את הקונטיינרים
  eks_managed_node_groups = {
    main_group = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.small"]
      ami_type       = "AL2_x86_64" # <--- הוסף את השורה הזו
    }
  }

  # מאפשר לקוברנטיס לתת הרשאות IAM לפודים
  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = "dev"
    Project     = "aviv-mission"
  }
}

# פלט שידפיס לנו את פקודת ההתחברות לקלאסטר בסיום ההקמה
output "configure_kubectl" {
  description = "Run this command to configure kubectl"
  value       = "aws eks update-kubeconfig --region us-east-1 --name ${module.eks.cluster_name}"
}

# --- טריק DevOps: המתנה להתעוררות הקלאסטר לפני התקנת ה-Helm ---
resource "time_sleep" "wait_for_eks" {
  depends_on      = [module.eks]
  create_duration = "30s"
}

# --- התקנת NGINX Ingress Controller אוטומטית בעזרת Helm ---
resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  # עכשיו ה-Helm מחכה ל-time_sleep, שבעצמו מחכה ל-EKS
  depends_on = [time_sleep.wait_for_eks]

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
}

# ==========================================
# IRSA - IAM Roles for Service Accounts
# יצירת תפקידים נפרדים ל-Backend ול-Worker
# ==========================================

# פוליסת הרשאות ל-Backend (כתיבה בלבד)
resource "aws_iam_policy" "backend_policy" {
  name        = "aviv-backend-policy"
  description = "Permissions for Backend Pod"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "sqs:SendMessage",
          "sns:Publish"
        ]
        Resource = "*"
      }
    ]
  })
}

module "iam_eks_role_backend" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version   = "~> 5.0"
  role_name = "aviv-mission-backend-role"

  role_policy_arns = {
    policy = aws_iam_policy.backend_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["devops-app:backend-sa"]
    }
  }
}

# פוליסת הרשאות ל-Worker (קריאה, מחיקה ופרסום)
resource "aws_iam_policy" "worker_policy" {
  name        = "aviv-worker-policy"
  description = "Permissions for Worker Pod"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sns:Publish"
        ]
        Resource = "*"
      }
    ]
  })
}

module "iam_eks_role_worker" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version   = "~> 5.0"
  role_name = "aviv-mission-worker-role"

  role_policy_arns = {
    policy = aws_iam_policy.worker_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["devops-app:worker-sa"]
    }
  }
}