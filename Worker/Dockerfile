FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# כאן אנחנו אומרים לדוקר להריץ את הוורקר שמאזין ל-SQS
CMD ["python", "worker_sqs.py"]