import boto3
import os

# --- הגדרות (מעודכן לפי ה-ARN שלך) ---
BUCKET_NAME = "new-mission-bucket"
TOPIC_ARN = arn:aws:sns:us-east-1:544471418394:mission-alerts:b6d08965-e410-4815-8eb7-f58601c48552
REGION = "us-east-1"

# שימוש ב-Session כדי להבטיח עבודה נכונה עם ה-IAM Role של ה-EC2
session = boto3.Session(region_name=REGION)
s3 = session.client('s3')
sns = session.client('sns')

def upload_and_notify(file_path):
    if not os.path.exists(file_path):
        print(f"❌ Error: The file {file_path} does not exist.")
        return

    file_name = os.path.basename(file_path)
    
    try:
        # 1. העלאה ל-S3
        print(f"⏳ Uploading {file_name} to S3...")
        s3.upload_file(file_path, BUCKET_NAME, file_name)
        print(f"✅ Successfully uploaded to {BUCKET_NAME}")

        # 2. שליחת הודעה מעוצבת ונקייה ל-SNS
        friendly_message = f"""
🚀 Mission Alert: New Log Uploaded!
----------------------------------
Hello Aviv,

A new log file has been processed successfully:
📄 File: {file_name}
📦 Bucket: {BUCKET_NAME}
✅ Status: Success

The system is running smoothly via Internet Gateway.
----------------------------------
        """
        
        print(f"⏳ Sending clean notification to SNS...")
        sns.publish(
            TopicArn=TOPIC_ARN,
            Message=friendly_message,
            Subject=f"Log Upload Success: {file_name}"
        )
        print("🎉 Success! Clean notification sent to your email.")

    except Exception as e:
        print(f"❌ unexpected Error: {e}")

# הרצה על קובץ הבדיקה שיצרנו
if __name__ == "__main__":
    upload_and_notify("/home/ec2-user/logs/test.log")
