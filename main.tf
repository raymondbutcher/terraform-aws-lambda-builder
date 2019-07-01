################################
# Validate the input variables #
################################

data "external" "validate" {
  count = var.enabled ? 1 : 0

  program = ["python", "${path.module}/validate.py"]
  query = {
    build_mode        = var.build_mode
    filename          = var.filename != null ? var.filename : ""
    s3_bucket         = var.s3_bucket != null ? var.s3_bucket : ""
    s3_key            = var.s3_key != null ? var.s3_key : ""
    s3_object_version = var.s3_object_version != null ? var.s3_object_version : ""
    source_code_hash  = var.source_code_hash != null ? var.source_code_hash : ""
    source_dir        = var.source_dir
    zip_files_dir     = "${path.module}/zip_files"
  }
}

###############################################
# Create a zip file from the source directory #
# (if build mode is FILENAME, LAMBDA, S3)     #
###############################################

data "aws_caller_identity" "current" {
  count = var.enabled && (var.build_mode == "LAMBDA" || var.build_mode == "S3") ? 1 : 0
}

data "aws_partition" "current" {
  count = var.enabled && (var.build_mode == "LAMBDA" || var.build_mode == "S3") ? 1 : 0
}

data "aws_region" "current" {
  count = var.enabled && (var.build_mode == "LAMBDA" || var.build_mode == "S3") ? 1 : 0
}

module "source_zip_file" {
  source = "github.com/raymondbutcher/terraform-archive-stable?ref=v0.0.4"

  enabled = var.enabled && var.build_mode != "DISABLED"

  empty_dirs  = var.empty_dirs
  output_path = var.build_mode == "FILENAME" ? var.filename : "${path.module}/zip_files/${data.aws_partition.current[0].partition}-${data.aws_region.current[0].name}-${data.aws_caller_identity.current[0].account_id}-${var.function_name}.zip"
  source_dir  = var.source_dir
}

#################################
# Upload the zip file to S3     #
# (if build mode is LAMBDA, S3) #
#################################

resource "aws_s3_bucket_object" "source_zip_file" {
  count = var.enabled && (var.build_mode == "LAMBDA" || var.build_mode == "S3") ? 1 : 0

  bucket = var.s3_bucket
  key    = var.build_mode == "LAMBDA" ? "${var.function_name}/${module.source_zip_file.output_sha}/source.zip" : var.s3_key
  source = module.source_zip_file.output_path

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  source_zip_file_s3_key = var.enabled && (var.build_mode == "LAMBDA" || var.build_mode == "S3") ? aws_s3_bucket_object.source_zip_file[0].key : null
}

#######################################
# Build the final package with Lambda #
# (if build mode is LAMBDA)           #
#######################################

locals {
  builder_filenames = {
    "nodejs8.10" = "nodejs.js"
    "python2.7"  = "python.py"
    "python3.6"  = "python.py"
    "python3.7"  = "python.py"
  }
  cloudformation_parameters = {
    Bucket    = var.s3_bucket
    KeyPrefix = var.function_name
    KeySource = local.source_zip_file_s3_key
    Runtime   = var.runtime
  }
  cloudformation_template_body = templatefile("${path.module}/lambda_builders/cfn.yaml.tmpl", {
    lambda_code        = file("${path.module}/lambda_builders/${local.builder_filenames[var.runtime]}")
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

#######################################
# Create an IAM role for the function #
# (if role is not supplied)           #
#######################################

module "role" {
  source = "git::https://gitlab.com/claranet-pcp/terraform/aws/terraform-aws-lambda-role.git?ref=v0.0.4"

  enabled = var.enabled && coalesce(var.create_role, var.role == null)

  function_name         = var.function_name
  cloudwatch_logs       = var.role_cloudwatch_logs
  custom_policies       = var.role_custom_policies
  custom_policies_count = var.role_custom_policies_count
  dead_letter_config    = var.dead_letter_config
  policy_arns           = var.role_policy_arns
  policy_arns_count     = var.role_policy_arns_count
  tags                  = var.tags
  vpc_config            = var.vpc_config
}

##############################
# Create the Lambda function #
##############################

resource "aws_lambda_function" "built" {
  count = var.enabled ? 1 : 0

  description                    = var.description
  filename                       = var.filename
  function_name                  = var.function_name
  handler                        = var.handler
  kms_key_arn                    = var.kms_key_arn
  layers                         = var.layers
  memory_size                    = var.memory_size
  publish                        = var.publish
  reserved_concurrent_executions = var.reserved_concurrent_executions
  role                           = var.role != null ? var.role : module.role.arn
  runtime                        = var.runtime
  s3_bucket                      = var.s3_bucket
  s3_key                         = var.build_mode == "LAMBDA" ? local.built_s3_key : var.s3_key
  s3_object_version              = var.s3_object_version
  source_code_hash               = var.build_mode == "FILENAME" || var.build_mode == "S3" ? module.source_zip_file.output_base64sha256 : var.source_code_hash
  tags                           = var.tags
  timeout                        = var.timeout

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_config == null ? [] : [var.dead_letter_config]
    content {
      target_arn = dead_letter_config.value.target_arn
    }
  }

  dynamic "environment" {
    for_each = var.environment == null ? [] : [var.environment]
    content {
      variables = environment.value.variables
    }
  }

  dynamic "tracing_config" {
    for_each = var.tracing_config == null ? [] : [var.tracing_config]
    content {
      mode = tracing_config.value.mode
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config == null ? [] : [var.vpc_config]
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnet_ids
    }
  }
}
