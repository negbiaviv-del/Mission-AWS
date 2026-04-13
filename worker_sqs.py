import boto3
import time

# הגדרות - שנה כאן לכתובת שקיבלת
QUEUE_URL = 'https://sqs.us-east-1.amazonaws.com/544471418394/mission-queue'
BUCKET_NAME = 'new-mission-bucket'
SNS_TOPIC = 'arn:aws:sns:us-east-1:544471418394:mission-alerts'

sqs = boto3.client('sqs', region_name='us-east-1')
s3 = boto3.client('s3', region_name='us-east-1')
sns = boto3.client('sns', region_name='us-east-1')

def start_worker():
    print(f"Worker is active and polling: {QUEUE_URL}")
    while True:
        # משיכת הודעה מהתור (Long Polling)
        response = sqs.receive_message(
            QueueUrl=QUEUE_URL,
            MaxNumberOfMessages=1,
            WaitTimeSeconds=10
        )

        if 'Messages' in response:
            for msg in response['Messages']:
                file_path = msg['Body'] # תוכן ההודעה: נתיב הקובץ
                handle = msg['ReceiptHandle']
                
                print(f"Processing file: {file_path}")
                try:
                    # העלאה ל-S3
                    file_name = file_path.split('/')[-1]
                    s3.upload_file(file_path, BUCKET_NAME, file_name)
                    
                    # שליחת התראה
                    sns.publish(
                        TopicArn=SNS_TOPIC,
                        Message=f"SUCCESS: File {file_name} processed via SQS queue.",
                        Subject="SQS Success Alert"
                    )

                    # מחיקה מהתור בסיום מוצלח
                    sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=handle)
                    print(f"Done! {file_name} uploaded and deleted from queue.")
                    
                except Exception as e:
                    print(f"Error processing {file_path}: {e}")

if __name__ == "__main__":
    start_worker()
