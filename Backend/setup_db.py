import psycopg2

# פרטי החיבור שלך
conn = psycopg2.connect(host="10.0.2.30", database="postgres", user="postgres", password="YourPassword")
cur = conn.cursor()

# 1. יצירת טבלה פשוטה
cur.execute("CREATE TABLE IF NOT EXISTS mission_data (id SERIAL PRIMARY KEY, name TEXT, status TEXT);")

# 2. הכנסת נתונים ראשוניים
cur.execute("INSERT INTO mission_data (name, status) VALUES ('Frontend Server', 'Operational'), ('Backend Server', 'Connected'), ('RDS Database', 'Synced');")

conn.commit()
print("Table created and data inserted successfully!")
cur.close()
conn.close()
