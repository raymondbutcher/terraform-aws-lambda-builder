resource "random_id" "bucket_name" {
  prefix      = "terraform-aws-lambda-builder-tests-"
  byte_length = 8
}

resource "aws_s3_bucket" "packages" {
  bucket = random_id.bucket_name.hex
  acl    = "private"
}

module "lambda_function" {
  source = "../../"

  build_mode           = "LAMBDA"
  function_name        = "terraform-aws-lambda-builder-numpy"
  handler              = "lambda.handler"
  role_cloudwatch_logs = true
  runtime              = "python3.6"
  s3_bucket            = aws_s3_bucket.packages.id
  source_dir           = "${path.module}/src"
  timeout              = 30
}

output "function_name" {
  value = module.lambda_function.function_name
}