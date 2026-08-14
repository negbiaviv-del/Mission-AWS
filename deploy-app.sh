#!/bin/bash
set -e

REGION="us-east-1"
ACCOUNT="544471418394"
ECR_URL="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"
NAMESPACE="devops-app"

echo "🔐 [1/5] Logging into AWS ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

echo "🛠️ [2/5] Initializing Docker Buildx..."
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes > /dev/null 2>&1 || true
docker buildx create --use --name multiarch-builder 2>/dev/null || docker buildx use multiarch-builder

echo "🏗️ [3/5] Building and pushing Docker images to ECR..."
# שימוש בשמות המאגרים התואמים למה ש-Terraform יצר
SERVICES=("mission-frontend" "mission-backend" "mission-worker")
DIRS=("./Frontend" "./Backend" "./Worker")

for i in "${!SERVICES[@]}"; do
    SERVICE="${SERVICES[$i]}"
    DIR="${DIRS[$i]}"
    
    echo "Building $SERVICE..."
    docker buildx build --platform linux/amd64 --no-cache -t $ECR_URL/$SERVICE:latest --push $DIR
done

echo "☸️ [4/5] Updating local kubeconfig and fetching IAM Roles..."
cd Terraform
CLUSTER_NAME=$(terraform output -raw configure_kubectl | awk -F'--name ' '{print $2}')

# משיכת שני התפקידים החדשים שיצרנו ב-Terraform
BACKEND_ROLE_ARN=$(terraform output -raw backend_iam_role_arn)
WORKER_ROLE_ARN=$(terraform output -raw worker_iam_role_arn)
cd ..

aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo "☸️ [5/5] Applying Kubernetes manifests..."
cd K8S
# ה-Namespace וה-Secrets כבר בפנים בזכות Terraform! עכשיו רק פורסים את האפליקציה:
kubectl apply -f backend/
kubectl apply -f worker/
kubectl apply -f frontend/
cd ..

# הזרקת תעודות הזהות של אמזון (IAM Roles) לתוך ה-ServiceAccounts בהתאמה
if [ -n "$BACKEND_ROLE_ARN" ] && [ -n "$WORKER_ROLE_ARN" ]; then
    echo "Injecting IAM Role ARN for Backend: $BACKEND_ROLE_ARN"
    kubectl annotate serviceaccount backend-sa -n $NAMESPACE eks.amazonaws.com/role-arn=$BACKEND_ROLE_ARN --overwrite

    echo "Injecting IAM Role ARN for Worker: $WORKER_ROLE_ARN"
    kubectl annotate serviceaccount worker-sa -n $NAMESPACE eks.amazonaws.com/role-arn=$WORKER_ROLE_ARN --overwrite
fi

echo "🔄 Performing a rollout restart to apply new images and roles..."
kubectl rollout restart deployment -n $NAMESPACE

echo "🎉 Automation completed successfully! The environment is bulletproof."