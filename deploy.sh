#!/bin/bash

# עוצר את הסקריפט אם משהו נכשל
set -e

echo "🚀 [1/3] Starting Terraform deployment..."
cd Terraform
terraform apply -auto-approve

echo "✅ Terraform deployed and Dynamic Inventory generated successfully!"

echo "⏳ [2/3] Waiting 30 seconds for EC2 instances to wake up and start SSH..."
sleep 30

echo "🛠️ [3/3] Launching Ansible configuration..."
cd ../ansible 

export ANSIBLE_HOST_KEY_CHECKING=False

ansible-playbook -i inventory.ini playbooks/site.yml 

echo "🎉 Deployment Completed Successfully! Your system is up and running."