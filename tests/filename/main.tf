provider "aws" {
  profile = "rbutcher"
  region  = "eu-west-1"
}

module "build_and_upload_directly" {
  source = "../../"

  build_mode    = "ZIPFILE"
  function_name = "terraform-aws-lambda-builder-filename1"
  handler       = "lambda.handler"
  runtime       = "python3.6"
  source_dir    = "${path.module}/src"
}

module "upload_directly" {
  source = "../../"

  function_name = "terraform-aws-lambda-builder-filename2"
  handler       = "lambda.handler"
  runtime       = "python3.6"
  filename      = "${path.module}/test2.zip"
}
