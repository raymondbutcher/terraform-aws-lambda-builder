provider "aws" {
  profile = "rbutcher"
  region  = "eu-west-1"
}

resource "random_id" "bucket_name" {
  prefix      = "terraform-aws-lambda-builder-tests-"
  byte_length = 8
}

resource "aws_s3_bucket" "packages" {
  bucket = random_id.bucket_name.hex
  acl    = "private"
}

module "zip_and_upload_without_build" {
  source = "../../"

  build_mode    = "S3"
  function_name = "terraform-aws-lambda-builder-s3"
  handler       = "lambda.handler"
  runtime       = "python3.6"
  s3_bucket     = aws_s3_bucket.packages.id
  s3_key        = "direct-s3-test.zip"
  source_dir    = "${path.module}/src"
}
