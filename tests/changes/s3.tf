resource "random_id" "bucket_name" {
  prefix      = "terraform-aws-lambda-builder-tests-"
  byte_length = 8
}

resource "aws_s3_bucket" "packages" {
  bucket = random_id.bucket_name.hex
  acl    = "private"
}

output "bucket" {
  value = aws_s3_bucket.packages.id
}
