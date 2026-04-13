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
| **Database** | RDS PostgreSQL | Private | `10.0.2.30:5432` |
| **Storage** | S3 Logs Bucket | Global | `s3://new-mission-bucket` |
| **Alerts** | SNS Topic | Global | `arn:aws:sns:us-east-1:544471418394:mission-alerts` |

---

## 🛠️ Infrastructure Details

### 1. Networking & Security
The architecture utilizes a direct **Internet Gateway (IGW)** routing strategy from the private route table to simplify outbound connectivity for the worker, eliminating the need for a costly NAT Gateway.

* **Security Groups (Least Privilege):**
    * `SG-Backend`: Restricted to traffic strictly from the Frontend.
    * `SG-Database`: Configured using **Security Group Referencing**. It accepts inbound traffic on Port 5432 **only** from the `SG-Backend` and `SG-Worker` group IDs.
    * `SG-Worker`: Allows SSH for management and HTTPS (443) for outbound AWS API calls to S3 and SNS.

### 2. Database Initialization
The RDS database is initialized using a custom Python script (`setup_db.py`) utilizing the `psycopg2` adapter.
* **Schema:** Creates the `mission_data` table (`id SERIAL PRIMARY KEY`, `name TEXT`, `status TEXT`).
* **Seeding:** Automatically inserts initial operational statuses for the Frontend and Backend servers to verify connectivity.

### 3. Monitoring & Formatted SNS Alerts
A custom background service (`worker.service`) manages the log lifecycle.
* **Custom Python Logic:** Using the `boto3` SDK, the Worker uploads logs to S3 and immediately triggers an **SNS Publish** event.
* **Why Boto3?** Standard S3 Event Notifications send raw, unreadable JSON. By triggering SNS via Python, we send a **clean, human-readable email** containing a formatted success summary.

---

## 🚀 Operations & Management

### File Management Across Tiers
Moving files between isolated instances (e.g., from Backend to Worker) is handled securely:
1. **Direct Internal Transfer:** Using `rsync` or `scp` via private IPs (`10.0.2.104`). This requires temporarily loading the `.pem` key onto the source server with strict `chmod 400` permissions.
2. **S3 Intermediary (Best Practice):** Utilizing the `new-mission-bucket` as a secure bridge to upload files from the Backend and pull them to the Worker using the `aws s3 cp` command, completely avoiding the placement of SSH keys on private servers.

### Security & Version Control
To maintain strict security within the repository, a `.gitignore` file is implemented to ensure:
* **Private Keys:** AWS SSH keys (e.g., `avivPair-01.pem`) are explicitly ignored to prevent unauthorized infrastructure access.
* **Log Files:** Dynamic files like `output.log` and `check.log` are excluded to keep commit histories clean.

### Accessing Private Instances:
```bash
# Jump through Bastion (Frontend) to Worker
ssh -i "avivPair-01.pem" ec2-user@32.192.23.230
ssh -i "avivPair-01.pem" ec2-user@10.0.2.104

# Managing the Worker Service:
sudo systemctl daemon-reload
sudo systemctl restart worker
sudo systemctl status worker