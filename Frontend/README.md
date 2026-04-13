# AWS 3-Tier Infrastructure & Monitoring System

This project demonstrates a scalable and secure 3-tier cloud architecture deployed on AWS. It features a decoupled monitoring system, automated log management, and a secure networking layer using a custom VPC and Subnets.

## 🏗️ Architecture Overview
The infrastructure follows AWS Best Practices for security and isolation, specifically optimized for cost and performance.

* **VPC:** Custom Virtual Private Cloud (`10.0.0.0/16`).
* **Public Subnet:** Hosts the user-facing Frontend (Nginx) and acts as a Bastion Host.
* **Private Subnet:** Houses the application logic (Flask), background workers (Python), and the managed database (RDS).

### Component Breakdown:

| Component | Function | Networking | IP / Port |
| :--- | :--- | :--- | :--- |
| **Frontend** | Nginx Reverse Proxy | Public | `32.192.23.230:80` |
| **Backend** | Flask REST API | Private | `10.0.2.246:5000` |
| **Worker** | Monitoring Service | Private | `10.0.2.104` |
| **Database** | RDS PostgreSQL | Private | Port `5432` |
| **Storage** | S3 Logs Bucket | Global | `s3://new-mission-bucket` |
| **Alerts** | SNS Topic | Global | `arn:aws:sns:us-east-1:544471418394:mission-alerts` |

---

## 🛠️ Infrastructure Details

### 1. Networking & Security (Updated)
The architecture has been migrated from a NAT Gateway to a direct **Internet Gateway (IGW)** routing strategy to simplify connectivity and reduce costs.

* **Routing:** The Private Route Table directs outbound traffic (`0.0.0.0/0`) via the Internet Gateway. This allows the Worker to reach S3 and SNS directly.
* **Security Groups (Least Privilege):**
    * `SG-Backend`: Restricted to traffic from the Frontend.
    * `SG-Database`: Specifically configured using **Security Group Referencing**. It accepts inbound traffic on Port 5432 **only** from the `SG-Backend` and `SG-Worker` group IDs.
    * `SG-Worker`: Allows SSH for management and HTTPS (443) for outbound AWS API calls.

### 2. Monitoring & Formatted SNS Alerts
A custom background service (`worker.service`) manages the log lifecycle.

* **Custom Python Logic:** Using the `boto3` SDK, the Worker uploads logs to S3 and immediately triggers an **SNS Publish** event.
* **Why Boto3?** Standard S3 Event Notifications send raw, unreadable JSON. By triggering SNS via Python, we send a **clean, human-readable email** containing a formatted success summary.

### 3. Data Flow
1. **User** accesses the Frontend; requests are proxied to the Backend.
2. **Worker** generates/collects logs and initiates an upload to S3.
3. **Connectivity:** The upload travels through the **Internet Gateway** (Port 443).
4. **Notification:** Upon success, the Worker sends a custom alert to the **SNS Topic**, which notifies the administrator via Email.

---

## 🚀 Operations & Management

### Accessing Private Instances:
```bash
# Jump through Bastion (Frontend) to Worker
ssh -i "avivPair-01.pem" ec2-user@32.192.23.230
ssh -i "avivPair-01.pem" ec2-user@10.0.2.104

# Managing the Worker Service:
sudo systemctl daemon-reload
sudo systemctl restart worker
sudo systemctl status worker