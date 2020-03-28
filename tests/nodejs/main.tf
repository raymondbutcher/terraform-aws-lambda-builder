resource "random_id" "bucket_name" {
  prefix      = "terraform-aws-lambda-builder-tests-"
  byte_length = 8
}

resource "aws_s3_bucket" "packages" {
  bucket = random_id.bucket_name.hex
  acl    = "private"
}

module "lambda_function_10" {
  source = "../../"

  build_mode           = "LAMBDA"
  function_name        = "terraform-aws-lambda-builder-nodejs-10"
  handler              = "index.handler"
  role_cloudwatch_logs = true
  runtime              = "nodejs10.x"
  s3_bucket            = aws_s3_bucket.packages.id
  source_dir           = "${path.module}/src"
  timeout              = 30
}

module "lambda_function_12" {
  source = "../../"

  build_mode           = "LAMBDA"
  function_name        = "terraform-aws-lambda-builder-nodejs-12"
  handler              = "index.handler"
  role_cloudwatch_logs = true
  runtime              = "nodejs12.x"
  s3_bucket            = aws_s3_bucket.packages.id
  source_dir           = "${path.module}/src"
  timeout              = 30
}

output "function_names" {
  value = [
    module.lambda_function_10.function_name,
    module.lambda_function_12.function_name,
  ]
}
