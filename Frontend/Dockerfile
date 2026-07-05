# שימוש בתמונת Nginx קלילה
FROM nginx:alpine

# מחיקת קובץ ההגדרות ברירת המחדל של Nginx
RUN rm /etc/nginx/conf.d/default.conf

# העתקת קובץ ההגדרות שלך אל תוך הקונטיינר
COPY flask.conf /etc/nginx/conf.d/

# חשיפת פורט 80 (הפורט הסטנדרטי של Nginx)
EXPOSE 80

# הפעלת שרת Nginx
CMD ["nginx", "-g", "daemon off;"]