# שימוש בתמונת בסיס של פייתון
FROM python:3.12-slim

# הגדרת תיקיית העבודה בתוך הקונטיינר
WORKDIR /app

# העתקת כל קבצי הפרויקט פנימה
COPY . /app

# פקודת ברירת מחדל להרצה
CMD ["python3", "-c", "print('Container is running successfully!')"]
