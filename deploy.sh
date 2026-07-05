#!/bin/bash

# עוצר את הסקריפט אם משהו נכשל
set -e

echo "🚀 [1/3] Planning Terraform deployment..."
cd Terraform
# יצירת תוכנית ושמירתה לקובץ
terraform plan -out=infrastructure.plan

echo "🚀 [2/3] Applying Terraform deployment..."
# הרצת ה-apply מתוך הקובץ השמור (ללא צורך ב-auto-approve)
terraform apply "infrastructure.plan"

echo "✅ Terraform deployed and Dynamic Inventory generated successfully!"

echo "🛠️ [3/3] Launching Ansible configuration..."
cd ../ansible 

export ANSIBLE_HOST_KEY_CHECKING=False

ansible-playbook -i inventory.ini playbooks/site.yml 

echo "🎉 Deployment Completed Successfully! Your system is up and running."