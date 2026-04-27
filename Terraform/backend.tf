terraform {
  backend "s3" {
    bucket  = "aviv-mission-aws-bucket-1997"  # השם של ה-S3 שיצרת
    key     = "mission-aws/terraform.tfstate" # הנתיב שבו יישמר הקובץ בתוך ה-Bucket
    region  = "us-east-1"                     # האזור שבו נמצא ה-Bucket
    encrypt = true                            # הצפנת הקובץ ב-S3
  }
}