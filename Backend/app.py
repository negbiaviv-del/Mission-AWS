import psycopg2
import os
import boto3
from flask import Flask, render_template_string, request, redirect, url_for

app = Flask(__name__)

S3_BUCKET_NAME = "new-mission-bucket"
SNS_TOPIC_ARN = "arn:aws:sns:us-east-1:544471418394:mission-alerts"
AWS_REGION = "us-east-1"

s3_client = boto3.client('s3', region_name=AWS_REGION)
sns_client = boto3.client('sns', region_name=AWS_REGION)

DB_CONFIG = {
    "host": "10.0.2.30",
    "database": "postgres",
    "user": "postgres",
    "password": os.getenv("DB_PASSWORD")
}

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Cloud Resource Monitor</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f4f4f9; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; background: white; }
        th, td { padding: 12px; border: 1px solid #ddd; text-align: left; }
        th { background-color: #232f3e; color: white; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .container { max-width: 800px; margin: auto; }
        .form-group { margin-bottom: 15px; }
        input, select { padding: 8px; width: 200px; }
        button { padding: 8px 15px; cursor: pointer; background-color: #ff9900; border: none; color: white; font-weight: bold; }
        .delete-btn { background-color: #d11a2a; }
    </style>
</head>
<body>
    <div class="container">
        <h2>AWS Infrastructure Monitoring</h2>
        <form action="/add" method="post">
            <input type="text" name="name" placeholder="Resource Name" required>
            <select name="status">
                <option value="Running">Running</option>
                <option value="Stopped">Stopped</option>
                <option value="Pending">Pending</option>
            </select>
            <button type="submit">Add Resource</button>
        </form>

        <table>
            <tr>
                <th>ID</th>
                <th>Resource Name</th>
                <th>Status</th>
                <th>Actions</th>
            </tr>
            {% for row in data_rows %}
            <tr>
                <td>{{ row[0] }}</td>
                <td>{{ row[1] }}</td>
                <td>{{ row[2] }}</td>
                <td>
                    <form action="/delete/{{ row[0] }}" method="post" style="display:inline;">
                        <button type="submit" class="delete-btn">Delete</button>
                    </form>
                </td>
            </tr>
            {% endfor %}
        </table>
    </div>
</body>
</html>
"""

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)

@app.route('/')
def index():
    rows = []
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, name, status FROM mission_data ORDER BY id DESC;")
        rows = cur.fetchall()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Database Error: {e}")
    return render_template_string(HTML_TEMPLATE, data_rows=rows)

@app.route('/add', methods=['POST'])
def add_entry():
    name = request.form.get('name')
    status = request.form.get('status')
    
    if name and status:
        try:
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute("INSERT INTO mission_data (name, status) VALUES (%s, %s);", (name, status))
            conn.commit()
            cur.close()
            conn.close()

            log_content = f"Resource: {name} | Status: {status} | Event: Created"
            file_key = f"logs/{name}_event.txt"
            s3_client.put_object(Bucket=S3_BUCKET_NAME, Key=file_key, Body=log_content)

            sns_message = f"Alert: New cloud resource '{name}' added with status '{status}'."
            sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=sns_message,
                Subject="Cloud Infrastructure Alert"
            )

        except Exception as e:
            print(f"Cloud Workflow Error: {e}")
            
    return redirect(url_for('index'))

@app.route('/delete/<int:entry_id>', methods=['POST'])
def delete_entry(entry_id):
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("DELETE FROM mission_data WHERE id = %s;", (entry_id,))
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Delete Error: {e}")
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
