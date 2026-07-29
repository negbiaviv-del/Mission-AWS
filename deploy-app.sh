#!/bin/bash
set -e

REGION="us-east-1"
ACCOUNT="544471418394"
ECR_URL="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"
NAMESPACE="devops-app"

echo "🔐 [1/8] Logging into AWS ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

echo "🛠️ [2/8] Initializing Docker Buildx & QEMU for Cross-Compilation..."
# הפעלת סביבת התאימות לאינטל ברקע
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes > /dev/null 2>&1 || true
# יצירה ושימוש ב-Builder מודרני אם הוא לא קיים
docker buildx create --use --name multiarch-builder 2>/dev/null || docker buildx use multiarch-builder
docker buildx inspect --bootstrap > /dev/null 2>&1

echo "🏗️ [3/8] Building Docker images for AWS (Intel/amd64)..."
docker buildx build --platform linux/amd64 --no-cache --load -t my-frontend:v1.0 ./Frontend
docker buildx build --platform linux/amd64 --no-cache --load -t my-backend:v1.0 ./Backend
docker buildx build --platform linux/amd64 --no-cache --load -t my-worker:v1.0 ./Worker

echo "🏷️ [4/8] Tagging and pushing images to ECR..."
SERVICES=("my-frontend" "my-backend" "my-worker")
for SERVICE in "${SERVICES[@]}"; do
    if ! aws ecr describe-repositories --repository-names $SERVICE --region $REGION > /dev/null 2>&1; then
        aws ecr create-repository --repository-name $SERVICE --image-scanning-configuration scanOnPush=true --region $REGION
    fi
    docker tag $SERVICE:v1.0 $ECR_URL/$SERVICE:v1.0
    docker push $ECR_URL/$SERVICE:v1.0
done

echo "🔗 [5/8] Fetching dynamic AWS Data from Terraform State..."
cd Terraform
DB_ADDRESS=$(terraform output -raw db_address)

# שאיבת סיסמת ושם משתמש ה-DB מטרפורם כדי למנוע שגיאות התחברות
DB_USER=$(terraform output -raw db_user)
DB_PASS=$(terraform output -raw db_password)

# שאיבת הכתובת האמיתית של תעודת הזהות (IAM Role) מאמזון
ROLE_PATH=$(terraform state list | grep aws_iam_role.ec2_role | head -n 1)
ROLE_ARN=$(terraform state show $ROLE_PATH | grep '^ *arn ' | awk '{print $3}' | tr -d '"')

# שאיבת השם המעודכן של ה-S3 Bucket שניווצר כעת
S3_PATH=$(terraform state list | grep aws_s3_bucket. | head -n 1)
S3_BUCKET=$(terraform state show $S3_PATH | grep '^ *bucket ' | awk '{print $3}' | tr -d '"')

# שאיבת שם קלאסטר ה-EKS באופן דינמי
CLUSTER_NAME=$(terraform output -raw configure_kubectl | awk -F'--name ' '{print $2}')
cd ..

# --- שלב האוטומציה החדש ---
echo "☸️ [6/8] Updating local kubeconfig for EKS Cluster ($CLUSTER_NAME)..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo "☸️ [7/8] Applying base Kubernetes manifests..."
cd K8S
kubectl apply -f config/namespace.yaml
kubectl apply -f config/configmaps.yaml
kubectl apply -f config/secret.yaml 

kubectl apply -f backend/
kubectl apply -f worker/
kubectl apply -f frontend/
cd ..

echo "⚡ [8/8] Injecting dynamic variables into Kubernetes in real-time..."

# 1. הזרקת כתובת הדאטהבייס לפודים
if [ -n "$DB_ADDRESS" ]; then
    kubectl set env deployment/backend DB_HOST=$DB_ADDRESS -n $NAMESPACE
fi

# 2. עדכון חכם של הסודות (סיסמה ומשתמש ל-DB)
if [ -n "$DB_USER" ] && [ -n "$DB_PASS" ]; then
    echo "Injecting DB Credentials into Secrets..."
    kubectl patch secret app-secrets -n $NAMESPACE -p="{\"stringData\": {\"DB_USER\": \"$DB_USER\", \"DB_PASSWORD\": \"$DB_PASS\"}}"
fi

# 3. הזרקת שם ה-S3 Bucket לתוך ה-ConfigMap
if [ -n "$S3_BUCKET" ]; then
    echo "Injecting S3 Bucket: $S3_BUCKET"
    kubectl patch configmap app-config -n $NAMESPACE -p="{\"data\": {\"S3_BUCKET_NAME\": \"$S3_BUCKET\"}}"
fi

# 4. הזרקת תעודת הזהות של אמזון (IAM Role) לתוך ה-ServiceAccount
if [ -n "$ROLE_ARN" ]; then
    echo "Injecting IAM Role ARN: $ROLE_ARN"
    kubectl annotate serviceaccount backend-sa -n $NAMESPACE eks.amazonaws.com/role-arn=$ROLE_ARN --overwrite
fi

echo "🔄 Performing a rollout restart to apply new configurations..."
kubectl rollout restart deployment/backend -n $NAMESPACE
kubectl rollout restart deployment/worker -n $NAMESPACE
kubectl rollout restart deployment/frontend -n $NAMESPACE

echo "🎉 Automation completed successfully! The environment is bulletproof."