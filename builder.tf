locals {
  builder_filenames = {
    "python2.7" = "python.py"
    "python3.6" = "python.py"
    "python3.7" = "python.py"
  }
  cloudformation_parameters = {
    Bucket    = var.s3_bucket
    KeyPrefix = var.function_name
    KeySource = local.source_zip_file_s3_key
    Runtime   = var.runtime
  }
  cloudformation_template_body = templatefile("${path.module}/builder.yaml.tmpl", {
    lambda_code        = file("${path.module}/builders/${local.builder_filenames[var.runtime]}")
    lambda_handler     = "index.handler"
    lambda_memory_size = var.builder_memory_size
    lambda_runtime     = var.runtime
    lambda_timeout     = var.builder_timeout
  })
}

# Create a random build_id that changes when the source zip
# or CloudFormation details changes.

resource "random_string" "build_id" {
  count = var.enabled && var.build_mode == "LAMBDA" ? 1 : 0

  length  = 16
  upper   = false
  special = false

  keepers = {
    cloudformation_parameters    = sha1(jsonencode(local.cloudformation_parameters))
    cloudformation_template_body = sha1(local.cloudformation_template_body)
  }
}

# Create a CloudFormation stack that builds a Lambda package and
# then outputs the location of the built package. Use the above
# build_id as part of the stack name. Stack name changes force
# the stack to be recreated. The result is a new build whenever
# there are changes to the source_dir or changes to this module.

resource "aws_cloudformation_stack" "builder" {
  count = var.enabled && var.build_mode == "LAMBDA" ? 1 : 0

  name         = "${var.s3_bucket}-${random_string.build_id[0].result}"
  capabilities = ["CAPABILITY_IAM"]
  on_failure   = "DELETE"

  parameters = merge(local.cloudformation_parameters, {
    KeyTarget = "${var.function_name}/${module.source_zip_file.output_sha}/${random_string.build_id[0].result}.zip"
  })

  template_body = local.cloudformation_template_body

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  built_s3_key = var.enabled && var.build_mode == "LAMBDA" ? aws_cloudformation_stack.builder[0].outputs.Key : null
}
