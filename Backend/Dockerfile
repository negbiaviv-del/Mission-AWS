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
CMD ["python", "app.py"]