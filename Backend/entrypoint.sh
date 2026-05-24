#!/bin/bash
# 1. הרצת סקריפט האתחול של מסד הנתונים
echo "Initializing Database..."
python3 setup_db.py

# 2. אם הסקריפט הצליח, מריצים את השרת (ה-Gunicorn)
echo "Starting Gunicorn..."
exec gunicorn --bind 0.0.0.0:5000 app:app