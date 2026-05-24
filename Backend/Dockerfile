FROM python:3.11-slim

# הגדרת תיקיית העבודה בתוך הקונטיינר
WORKDIR /app

# העתקת קובץ הדרישות קודם (כדי לחסוך זמן בבנייה חוזרת)
COPY requirements.txt .

# התקנת הספריות
RUN pip install --no-cache-dir -r requirements.txt

# העתקת שאר קבצי הפרויקט (קוד, תמונות, HTML)
COPY . .

# פתיחת פורט 5000 כלפי חוץ (לדוקר)
EXPOSE 5000

# הפקודה שמריצה את השרת
RUN pip install gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]

# העתקת הסקריפט לקונטיינר
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# שימוש בסקריפט כנקודת כניסה
ENTRYPOINT ["/entrypoint.sh"]