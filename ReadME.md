# Final Project: Automated and Distributed 3-Tier Cloud Infrastructure on AWS

**Submitted by:** Aviv Negbi  
**Course / Lecturer:** Aviad  
**Date Updated:** May 2026  

---

## 📋 Project Overview
This project presents an advanced, secure, and distributed cloud architecture using a **3-Tier Architecture** model on **AWS**. The entire system is provisioned and managed utilizing **Infrastructure as Code (IaC)** and **Configuration as Code (CaC)** methodologies, enabling full reproducibility, high reliability, and a true **One-Click Deployment** process.

In the final phase of the project, the architecture was upgraded from standard EC2 instances to a fully orchestrated **Kubernetes (Amazon EKS)** environment. 

The system seamlessly integrates four main domains:
1. **Infrastructure Provisioning (IaC):** Utilizing **Terraform** to build the physical backbone on AWS (VPC, EKS Cluster, RDS, S3, SQS, SNS, and ECR).
2. **Configuration Management & CI/CD (CaC):** Utilizing **Ansible** running locally to build cross-platform Docker images, push them to AWS ECR, and dynamically inject real-time infrastructure data into Kubernetes manifests.
3. **Container Orchestration:** Packaging the Application logic using **Docker** and orchestrating it via **Kubernetes** Deployments, Services, and an Nginx Ingress Controller.
4. **Application Layer:** A distributed application featuring a Backend API (Flask) and a background Worker, integrated with **RDS**, **S3**, **SQS**, and **SNS** for asynchronous processing and alerting.

---

## 🛠️ Tech Stack
* **Cloud Provider:** AWS (VPC, EKS, ALB / Ingress, RDS PostgreSQL, S3, SQS, SNS, ECR)
* **Infrastructure as Code:** Terraform 1.14.9
* **Configuration Management:** Ansible (Local execution pipeline)
* **Containerization & Orchestration:** Docker, Buildx (QEMU), Kubernetes (`kubectl`)
* **Backend Application:** Python 3.x, Flask, Boto3 (AWS SDK), Psycopg2 (PostgreSQL Driver)
* **Frontend UI:** HTML5, Tailwind CSS, Nginx (Unprivileged Reverse Proxy)
* **Helm:** Utilized for provisioning and managing the Nginx Ingress Controller to handle cluster traffic routing.

---

## 🏗️ Architecture & Component Breakdown

### 1. Infrastructure Layer (Terraform)
The infrastructure is written modularly, creating a highly secure environment:
* **Networking (VPC):** Provisioning public subnets for the Ingress Controller (Load Balancer) and secure private subnets for the EKS Worker Nodes and Database.
* **Compute (EKS):** Amazon Elastic Kubernetes Service manages the application pods, ensuring high availability, self-healing, and scalability.
* **Database (RDS PostgreSQL):** Provisioned within a private `aws_db_subnet_group`, completely blocked from the external internet and accessible only by the internal Kubernetes App tier.
* **AWS Services (S3, SQS, SNS):** Provisioning storage buckets for configurations, an asynchronous message queue (`mission-queue-v2`), and an alert topic for real-time administrator emails.
* **Container Registry (ECR):** Secure, private repositories to store the custom Frontend, Backend, and Worker Docker images.

### 2. Configuration & Deployment Layer (Ansible)
Instead of connecting to remote servers via SSH, the Ansible Playbook (`deploy.yml`) acts as a local CI/CD pipeline manager:
* **Cross-Platform Image Building:** Utilizes Docker Buildx and QEMU to ensure images built on local machines (e.g., ARM processors) are compiled for target EKS worker nodes (Intel/amd64).
* **Dynamic State Fetching:** Ansible seamlessly fetches live infrastructure outputs directly from the Terraform State (DB endpoints, IAM Role ARNs, S3 Bucket names).
* **Real-time Manifest Injection:** Instead of static template files, Ansible dynamically patches Kubernetes **Secrets**, **ConfigMaps**, and **ServiceAccounts** using `kubectl patch` and `kubectl set env`, ensuring secure and immediate injection of dynamic variables without writing them to disk.
* **Traffic Management:** The Nginx Ingress Controller was deployed via **Helm** to serve as the main gateway, receiving external traffic from the AWS Load Balancer and dynamically routing it to the internal application services.

---

## 🔐 Security & Secrets Management
This project strictly adheres to DevOps and Kubernetes security best practices:
* **No Hardcoded Secrets:** Passwords and runtime environments are **never** committed to version control.
* **Kubernetes Secrets:** Sensitive deployment variables (like the RDS master password) are injected directly into Kubernetes Secrets at runtime, rather than being saved in `.env` files inside the containers.
* **IRSA (IAM Roles for Service Accounts):** The Backend and Worker Pods do not use long-term AWS access keys. Instead, Terraform provisions an OIDC provider mapped to a specific IAM Role, which is annotated onto the Kubernetes ServiceAccount. This ensures the principle of least privilege.
* **Non-Root Containers:** The Frontend Nginx container is built using `nginxinc/nginx-unprivileged` and runs as user `101` on port `8080`, mitigating the risk of privilege escalation attacks inside the cluster.

---

## ⚡ Deployment Instructions

### Prerequisites
* Terraform, Ansible, AWS CLI, Docker, and `kubectl` installed on the local machine.
* Valid AWS Credentials configured.
* **Local Secrets Configuration:** Create a file named `outputs.tf` in the Terraform directory containing the necessary `sensitive = true` output blocks for your database credentials.

### One-Click Execution
The entire deployment lifecycle is orchestrated from your local machine. Run the following commands from the root directory:

```bash
# 1. Provision AWS resources
cd Terraform
terraform init
terraform apply -auto-approve

# 2. CRITICAL STEP - Subscription Confirmation
# AWS will send an automatic SNS confirmation email during the Terraform phase. 
# You MUST open your inbox and click "Confirm Subscription"!

# 3. Deploy the application via Ansible Pipeline
cd ..
ansible-playbook deploy.yml
```

### 🎯 Verification & Testing
To ensure the system is fully operational:
1. **Access the Application:** Run `kubectl get ingress -n devops-app` to retrieve the active Load Balancer address and navigate to it in your browser.
2. **Database Test:** Ensure the application successfully loads and displays historical data from the RDS database.
3. **Workflow Test:** Submit a new request via the UI. Verify a JSON file is created in the S3 Bucket, a message is dispatched to SQS, and an SNS Alert email is received.

### 🗑️ Teardown / Destroy
To safely remove all AWS resources and avoid charges:

    cd Terraform
    terraform destroy -auto-approve

---

## 🛠️ Troubleshooting & Lessons Learned
During the evolution of this project, particularly the migration to Kubernetes, several advanced challenges were resolved:

1. **Cross-Architecture Compilation (exec format error)**
   * **Problem:** Docker images built locally (on ARM architecture) crashed immediately when deployed to Amazon EKS (Intel t3.micro nodes) with an exec format error.
   * **Solution:** Integrated Docker Buildx and QEMU emulators into the Ansible pipeline, ensuring all images are forcefully compiled for linux/amd64 regardless of the host machine's architecture.

2. **Kubernetes Internal Routing (502 Bad Gateway)**
   * **Problem:** The Nginx Ingress successfully reached the Frontend, but requests returned a 502 error because the Frontend container could not locate the Backend.
   * **Solution:** Shifted from static IP mapping to Kubernetes internal DNS. Updated the Nginx default.conf to proxy pass requests directly to the Service name (http://backend-service:5000), allowing seamless service discovery.

3. **Dynamic Inventory vs. Hardcoding**
   * **Problem:** Managing environment variables that are determined only at runtime (like RDS and S3 endpoints) in a Kubernetes environment without committing them to Git.
   * **Solution:** Implemented a dynamic Ansible pipeline that reads the local terraform.tfstate and patches the live cluster using kubectl patch secret and kubectl annotate serviceaccount, creating a bulletproof, automated handoff between IaC and Kubernetes orchestration.
   
4. **IAM Roles (IRSA) & SQS Visibility Loop**
   * **Problem:** The Worker pod initially experienced an `AccessDenied` error when assuming the IAM role via OIDC. After fixing the trust policy, the Worker successfully read messages and triggered SNS, but entered an infinite loop, processing the same message over and over.
   * **Solution:** First, updated the AWS Trust Policy `Condition` array to explicitly trust both `backend-sa` and `worker-sa`. Second, realized the SQS visibility timeout was expiring because the Worker lacked deletion permissions. Added the `sqs:DeleteMessage` action to the Terraform IAM policy, allowing the Worker to properly complete the message lifecycle and break the loop.