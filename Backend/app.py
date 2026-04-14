import os
import json
import psycopg2
from psycopg2.extras import RealDictCursor
import boto3
from flask import Flask, render_template_string, request, redirect, url_for, flash, Response, jsonify

app = Flask(__name__)
app.secret_key = "aviv-cloud-mission-complete-v9"

# --- AWS Configuration ---
SQS_QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/544471418394/mission-queue"
S3_BUCKET_NAME = "new-mission-bucket"
SNS_TOPIC_ARN = "arn:aws:sns:us-east-1:544471418394:mission-alerts"
AWS_REGION = "us-east-1"

s3_client = boto3.client('s3', region_name=AWS_REGION)
sns_client = boto3.client('sns', region_name=AWS_REGION)
sqs_client = boto3.client('sqs', region_name=AWS_REGION)

DB_CONFIG = {
    "host": "10.0.2.30",
    "database": "postgres",
    "user": "postgres",
    "password": os.getenv("DB_PASSWORD")
}

# --- HTML Template ---
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Infrastructure Setup</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        .bg-brand { background-color: #635BFF; }
        .hover-bg-brand:hover { background-color: #5048E5; }
        body { background-color: #F8F9FC; }
        .modal { transition: opacity 0.25s ease; }
        body.modal-active { overflow: hidden; }
    </style>
</head>
<body class="min-h-screen text-slate-800 font-sans">

    <div class="p-6 flex justify-between items-start">
        <div class="flex flex-col gap-2 text-sm font-medium text-gray-600">
            <div class="bg-white px-4 py-2 rounded-lg shadow-sm border border-gray-100 flex items-center gap-2">
                <span class="w-2.5 h-2.5 bg-green-500 rounded-full animate-pulse"></span>
                Backend <span class="text-green-500 ml-1">Online</span>
            </div>
            <div class="bg-white px-4 py-2 rounded-lg shadow-sm border border-gray-100 flex items-center gap-2">
                <span class="w-2.5 h-2.5 bg-green-500 rounded-full animate-pulse"></span>
                Auth <span class="text-green-500 ml-1">Online</span>
            </div>
        </div>
        <div class="flex items-center gap-4 bg-white px-6 py-3 rounded-full shadow-sm border border-gray-100">
            <span class="text-gray-700 font-medium">Welcome, Aviv Negbi 👋</span>
            <div class="h-6 w-px bg-gray-200 mx-2"></div>
            <button class="text-gray-600 hover:text-brand flex items-center gap-2 text-sm font-semibold">
                <i class="fa-solid fa-user"></i> My Profile
            </button>
        </div>
    </div>

    <div class="max-w-5xl mx-auto px-4 pb-20">
        
        {% with messages = get_flashed_messages(with_categories=true) %}
            {% if messages %}
                {% for category, message in messages %}
                    <div class="mb-6 p-6 rounded-2xl shadow-lg border-l-8 flex justify-between items-center {% if category == 'success' %} bg-green-50 border-green-500 text-green-800 {% else %} bg-red-50 border-red-500 text-red-800 {% endif %}">
                        <div>
                            <i class="fa-solid {% if category == 'success' %}fa-circle-check text-green-500{% else %}fa-circle-exclamation text-red-500{% endif %} text-xl mr-3"></i>
                            <span class="font-bold text-lg">{{ message }}</span>
                        </div>
                        {% if category == 'success' and last_id %}
                        <button onclick="fetchPreview({{ last_id }})" class="bg-brand hover-bg-brand text-white px-6 py-2 rounded-xl font-bold transition-all shadow-md flex items-center gap-2">
                            <i class="fa-solid fa-eye"></i> Preview Configuration
                        </button>
                        {% endif %}
                    </div>
                {% endfor %}
            {% endif %}
        {% endwith %}

        <div class="bg-white rounded-[2rem] shadow-xl shadow-indigo-100/50 border border-gray-100 p-12 mb-12">
            <h1 class="text-3xl font-bold text-center mb-10 text-gray-900 tracking-tight">Infrastructure Setup</h1>
            <form action="/add" method="POST" class="grid grid-cols-1 md:grid-cols-2 gap-x-10 gap-y-8">
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-2 text-center">Number of Instances</label>
                    <input type="number" name="instances" value="2" min="1" max="10" class="w-full bg-gray-50 border border-gray-200 rounded-xl p-3.5 text-center outline-none focus:ring-2 focus:ring-brand">
                </div>
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-2 text-center">Base Machine Name</label>
                    <input type="text" name="name" placeholder="PROJECT-X" required class="w-full bg-gray-50 border border-gray-200 rounded-xl p-3.5 text-center outline-none focus:ring-2 focus:ring-brand">
                </div>
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-2 text-center">Operating System</label>
                    <select name="os" class="w-full bg-gray-50 border border-gray-200 rounded-xl p-3.5 text-center outline-none bg-white">
                        <option>Ubuntu 22.04 LTS</option>
                        <option>Amazon Linux 2023</option>
                    </select>
                </div>
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-2 text-center">Instance Type</label>
                    <select name="instance_type" class="w-full bg-gray-50 border border-gray-200 rounded-xl p-3.5 text-center outline-none bg-white">
                        <option value="t2.nano">t2.nano (1 vCPU, 0.5GB RAM)</option>
                        <option value="t2.micro">t2.micro (1 vCPU, 1GB RAM)</option>
                    </select>
                </div>
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-2 text-center">Post-Launch Script</label>
                    <select name="script" class="w-full bg-gray-50 border border-gray-200 rounded-xl p-3.5 text-center outline-none bg-white">
                        <option>Install & Configure Nginx</option>
                        <option>Docker Setup</option>
                        <option>None</option>
                    </select>
                </div>
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-2 text-center">Output Type</label>
                    <select name="output_type" class="w-full bg-gray-50 border border-blue-400 ring-2 ring-blue-50 rounded-xl p-3.5 text-center outline-none bg-white font-bold text-blue-600">
                        <option>JSON Configuration</option>
                        <option>Terraform (.tf) File</option>
                    </select>
                </div>
                <div class="md:col-span-2 mt-4">
                    <button type="submit" class="w-full bg-brand hover-bg-brand text-white font-bold text-lg py-4 rounded-2xl transition-all shadow-lg shadow-indigo-100 flex items-center justify-center gap-2">
                        <i class="fa-solid fa-plus-circle"></i> Create Instances
                    </button>
                </div>
            </form>
        </div>

        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <div class="p-6 border-b border-gray-50 flex justify-between items-center bg-gray-50/50">
                <h2 class="text-xl font-bold text-gray-800 tracking-tight">Active Infrastructure</h2>
                <span class="bg-indigo-100 text-indigo-700 px-3 py-1 rounded-full text-xs font-bold">{{ data_rows|length }} Active</span>
            </div>
            <table class="w-full text-left">
                <thead class="bg-gray-50 text-gray-400 text-xs uppercase tracking-widest">
                    <tr>
                        <th class="p-5 font-semibold">ID</th>
                        <th class="p-5 font-semibold">Name</th>
                        <th class="p-5 font-semibold text-center">Instance Type</th>
                        <th class="p-5 font-semibold text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-50">
                    {% for row in data_rows %}
                    <tr class="hover:bg-gray-50/50 transition-colors">
                        <td class="p-5 text-gray-400 font-mono">#{{ row['id'] }}</td>
                        <td class="p-5 font-bold text-gray-700">{{ row['name'] }}</td>
                        <td class="p-5 text-center">
                            <span class="px-3 py-1.5 rounded-lg text-xs font-bold bg-green-100 text-green-700 border border-green-200">
                                {{ row['display_type'] }}
                            </span>
                        </td>
                        <td class="p-5 text-right flex justify-end gap-2">
                            <button onclick="fetchPreview({{ row['id'] }})" class="text-indigo-400 hover:text-indigo-600 p-2"><i class="fa-solid fa-eye text-lg"></i></button>
                            <form action="/delete/{{ row['id'] }}" method="POST" class="inline">
                                <button class="text-red-300 hover:text-red-500 p-2"><i class="fa-solid fa-trash-can text-lg"></i></button>
                            </form>
                        </td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>
    </div>

    <div id="modal" class="modal opacity-0 pointer-events-none fixed w-full h-full top-0 left-0 flex items-center justify-center z-50">
        <div class="modal-overlay absolute w-full h-full bg-gray-900 opacity-60"></div>
        <div class="modal-container bg-white w-11/12 md:max-w-2xl mx-auto rounded-[2rem] shadow-2xl z-50 overflow-hidden">
            <div class="modal-content py-8 px-10 text-left">
                <div class="flex justify-between items-center pb-5 border-b border-gray-100 mb-6">
                    <p class="text-xl font-bold text-gray-800" id="modalFileName">infra_config.json</p>
                    <div class="cursor-pointer text-gray-400 hover:text-gray-600" onclick="closeModal()">
                        <i class="fa-solid fa-xmark text-2xl"></i>
                    </div>
                </div>
                <div class="bg-slate-900 rounded-2xl p-6">
                    <pre class="text-blue-300 font-mono text-sm leading-relaxed overflow-x-auto" id="jsonPreview">Loading...</pre>
                </div>
                <div class="flex justify-end pt-8 gap-4">
                    <button onclick="closeModal()" class="px-6 py-2 bg-gray-100 text-gray-500 font-bold rounded-xl hover:bg-gray-200 transition-all">Close</button>
                    <a id="downloadBtn" href="#" class="px-8 py-2 bg-brand text-white font-bold rounded-xl hover-bg-brand shadow-lg shadow-indigo-100 transition-all flex items-center gap-2">
                        <i class="fa-solid fa-download"></i> Download Full JSON
                    </a>
                </div>
            </div>
        </div>
    </div>

    <script>
        function fetchPreview(id) {
            fetch(`/api/preview/${id}`)
                .then(res => res.json())
                .then(data => {
                    document.getElementById('jsonPreview').innerText = JSON.stringify(data, null, 4);
                    document.getElementById('modalFileName').innerText = "config_" + data.Base_Machine_Name + ".json";
                    document.getElementById('downloadBtn').href = "/download/" + id;
                    
                    const modal = document.getElementById('modal');
                    modal.classList.remove('opacity-0', 'pointer-events-none');
                    document.body.classList.add('modal-active');
                });
        }

        function closeModal() {
            const modal = document.getElementById('modal');
            modal.classList.add('opacity-0', 'pointer-events-none');
            document.body.classList.remove('modal-active');
        }
    </script>
</body>
</html>
"""

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)

@app.route('/')
def index():
    rows = []
    last_id = request.args.get('last_id')
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("SELECT id, name, status FROM mission_data WHERE id > 4 ORDER BY id DESC;")
                db_rows = cur.fetchall()
                
                # עיבוד הנתונים להצגה נקייה בטבלה
                for r in db_rows:
                    try:
                        data = json.loads(r['status'])
                        r['display_type'] = data.get('Instance_Type', 'Unknown')
                    except:
                        r['display_type'] = r['status']
                    rows.append(r)
                    
    except Exception as e:
        flash(f"DB Error: {e}", "error")
    return render_template_string(HTML_TEMPLATE, data_rows=rows, last_id=last_id)

@app.route('/add', methods=['POST'])
def add_entry():
    # איסוף כל 6 השדות מהטופס
    name = request.form.get('name')
    instances = request.form.get('instances')
    os_type = request.form.get('os')
    instance_type = request.form.get('instance_type')
    script = request.form.get('script')
    output_type = request.form.get('output_type')
    
    if name and instance_type:
        try:
            # בניית אובייקט הנתונים המלא
            full_payload = {
                "Base_Machine_Name": name,
                "Number_of_Instances": instances,
                "Operating_System": os_type,
                "Instance_Type": instance_type,
                "Post_Launch_Script": script,
                "Infrastructure_Output_Type": output_type,
                "Created_At": "2026-04-14 21:51:00"
            }

            # 1. שמירה ב-RDS - אנחנו שומרים את ה-JSON המלא בתוך עמודת ה-status
            with get_db_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        "INSERT INTO mission_data (name, status) VALUES (%s, %s) RETURNING id;", 
                        (name, json.dumps(full_payload))
                    )
                    new_id = cur.fetchone()[0]

            # 2. AWS Operations (SQS & S3)
            sqs_client.send_message(QueueUrl=SQS_QUEUE_URL, MessageBody=json.dumps(full_payload))
            s3_client.put_object(
                Bucket=S3_BUCKET_NAME, 
                Key=f"logs/config_{name}.json", 
                Body=json.dumps(full_payload, indent=4)
            )

            # 3. SNS - מעוצב עם כל הפרטים
            sns_message = f"""
======= 🚀 CLOUD DEPLOYMENT ALERT =======

📌 Project: {name}
-------------------------------------------
🖥️  Type:      {instance_type}
🔢  Quantity:  {instances}
💿  OS:        {os_type}
📜  Script:    {script}
📦  Output:    {output_type}
-------------------------------------------
✅ Status: All details saved to RDS & S3
🛠️  Managed by: Aviv's Cloud Infrastructure

===========================================
"""
            sns_client.publish(TopicArn=SNS_TOPIC_ARN, Message=sns_message, Subject=f"🔥 Full Config Created: {name}")

            flash(f"Successfully created '{name}' with all 6 parameters!", "success")
            return redirect(url_for('index', last_id=new_id))
            
        except Exception as e:
            flash(f"System Error: {str(e)}", "error")
            
    return redirect(url_for('index'))

@app.route('/api/preview/<int:entry_id>')
def api_preview(entry_id):
    """מושך את ה-JSON המלא מה-DB ומחזיר אותו לתצוגה המקדימה"""
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("SELECT * FROM mission_data WHERE id = %s;", (entry_id,))
                row = cur.fetchone()
                # מחזירים את ה-JSON ששמרנו בתוך ה-status
                return jsonify(json.loads(row['status']))
    except:
        return jsonify({"error": "Not found"}), 404

@app.route('/download/<int:entry_id>')
def download_config(entry_id):
    """מוריד את קובץ ה-JSON המלא עם כל הפרטים המקוריים"""
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("SELECT * FROM mission_data WHERE id = %s;", (entry_id,))
                row = cur.fetchone()
                full_json = json.loads(row['status'])
                
                return Response(
                    json.dumps(full_json, indent=4),
                    mimetype="application/json",
                    headers={"Content-disposition": f"attachment; filename=config_{row['name']}.json"}
                )
    except:
        return "Error", 500

@app.route('/delete/<int:entry_id>', methods=['POST'])
def delete_entry(entry_id):
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("DELETE FROM mission_data WHERE id = %s;", (entry_id,))
        flash("Record deleted.", "success")
    except Exception as e:
        flash(f"Error: {e}", "error")
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)