FROM python:3.11-slim

# הגדרת תיקיית העבודה בתוך הקונטיינר
WORKDIR /app

# העתקת קובץ הדרישות קודם
COPY requirements.txt .

# התקנת הספריות וגוניקורן יחד בשלב מוקדם
RUN pip install --no-cache-dir -r requirements.txt && pip install gunicorn

# העתקת שאר קבצי הפרויקט
COPY . .

# העתקת הסקריפט לקונטיינר והפיכתו לבר-ביצוע
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# פתיחת פורט 5000 כלפי חוץ
EXPOSE 5000

# שימוש בסקריפט כנקודת כניסה
ENTRYPOINT ["/entrypoint.sh"]

# הפקודה שתועבר ל-entrypoint (תמיד בסוף הקובץ!)
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]