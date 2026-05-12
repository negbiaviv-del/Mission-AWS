import os
import psycopg2

# משיכת פרטי החיבור ממשתני סביבה במקום נתונים קשיחים (Hardcoded)
DB_HOST = os.getenv("DB_HOST", "10.0.2.30") # נשאר כדיפולט אבל ניתן לדריסה
DB_NAME = os.getenv("DB_NAME", "postgres")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD")

def setup_database():
    if not DB_PASSWORD:
        print("[-] ERROR: DB_PASSWORD environment variable is missing!")
        print("Please export DB_PASSWORD='your_password' before running.")
        exit(1)

    try:
        # התחברות מאובטחת
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        cur = conn.cursor()

        # 1. יצירת טבלה 
        cur.execute("CREATE TABLE IF NOT EXISTS mission_data (id SERIAL PRIMARY KEY, name TEXT, status TEXT);")

        # 2. הכנסת נתונים ראשוניים
        cur.execute("""
            INSERT INTO mission_data (name, status) 
            VALUES 
            ('Frontend Server', 'Operational'), 
            ('Backend Server', 'Connected'), 
            ('RDS Database', 'Synced');
        """)

        conn.commit()
        print("[+] Table created and data inserted successfully!")

    except psycopg2.Error as e:
        print(f"[-] Database error occurred: {e}")
    except Exception as e:
        print(f"[-] An unexpected error occurred: {e}")
    finally:
        # סגירת החיבורים בצורה בטוחה
        if 'cur' in locals() and cur is not None:
            cur.close()
        if 'conn' in locals() and conn is not None:
            conn.close()

if __name__ == "__main__":
    setup_database()