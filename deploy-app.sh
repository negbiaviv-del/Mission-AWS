#!/bin/bash
set -e

REGION="us-east-1"
ACCOUNT="544471418394"
ECR_URL="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"
NAMESPACE="devops-app"

echo "🔐 [1/7] Logging into AWS ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

echo "🛠️ [2/7] Initializing Docker Buildx..."
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes > /dev/null 2>&1 || true
docker buildx create --use --name multiarch-builder 2>/dev/null || docker buildx use multiarch-builder

echo "🏗️ [3/7] Building and pushing Docker images to ECR..."
SERVICES=("mission-frontend" "mission-backend" "mission-worker")
DIRS=("./Frontend" "./Backend" "./Worker")

for i in "${!SERVICES[@]}"; do
    SERVICE="${SERVICES[$i]}"
    DIR="${DIRS[$i]}"
    
    echo "Building $SERVICE..."
    docker buildx build --platform linux/amd64 --no-cache -t $ECR_URL/$SERVICE:latest --push $DIR
done

echo "☸️ [4/7] Updating local kubeconfig and fetching IAM Roles..."
cd Terraform
CLUSTER_NAME=$(terraform output -raw configure_kubectl | awk -F'--name ' '{print $2}')
BACKEND_ROLE_ARN=$(terraform output -raw backend_iam_role_arn)
WORKER_ROLE_ARN=$(terraform output -raw worker_iam_role_arn)
cd ..

aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo "🌐 [5/7] Fetching dynamic AWS Load Balancer DNS..."
LB_HOSTNAME=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

while [ -z "$LB_HOSTNAME" ]; do
    echo "⏳ Waiting for AWS to assign Load Balancer DNS..."
    sleep 5
    LB_HOSTNAME=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
done
echo "✅ Load Balancer DNS is ready: $LB_HOSTNAME"

echo "🔒 [6/7] Managing Kubernetes Secrets & dynamic TLS..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

if [ -f "./K8S/secrets.env" ]; then
    kubectl create secret generic app-secrets --from-env-file=./K8S/secrets.env -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
fi

echo "⚙️ Generating Self-Signed TLS Certificate..."
kubectl delete secret mission-tls -n $NAMESPACE --ignore-not-found 2>/dev/null || true

# התיקון הקריטי: משתמשים בשם קצר ל-CN כדי לעקוף את מגבלת 64 התווים!
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=mission-app" 2>/dev/null

kubectl create secret tls mission-tls --key /tmp/tls.key --cert /tmp/tls.crt -n $NAMESPACE
rm -f /tmp/tls.key /tmp/tls.crt

echo "📝 [7/7] Applying Kubernetes manifests (Generating dynamic Ingress)..."
cd K8S

cat <<EOF > frontend/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: devops-app
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - $LB_HOSTNAME
    secretName: mission-tls
  rules:
  - host: $LB_HOSTNAME
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 8080
EOF

if [ -f "network-policies.yaml" ]; then
    kubectl apply -f network-policies.yaml
fi
kubectl apply -f backend/
kubectl apply -f worker/
kubectl apply -f frontend/
cd ..

if [ -n "$BACKEND_ROLE_ARN" ] && [ -n "$WORKER_ROLE_ARN" ]; then
    kubectl annotate serviceaccount backend-sa -n $NAMESPACE eks.amazonaws.com/role-arn=$BACKEND_ROLE_ARN --overwrite
    kubectl annotate serviceaccount worker-sa -n $NAMESPACE eks.amazonaws.com/role-arn=$WORKER_ROLE_ARN --overwrite
fi

echo "🔄 Performing a rollout restart..."
kubectl rollout restart deployment -n $NAMESPACE

echo "🎉 Automation completed successfully! Access your app securely at: https://$LB_HOSTNAME"