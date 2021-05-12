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
# (if build mode is not DISABLED)             #
###############################################

data "aws_caller_identity" "current" {
  count = var.enabled && var.build_mode != "DISABLED" ? 1 : 0
}

data "aws_partition" "current" {
  count = var.enabled && var.build_mode != "DISABLED" ? 1 : 0
}

data "aws_region" "current" {
  count = var.enabled && var.build_mode != "DISABLED" ? 1 : 0
}

module "source_zip_file" {
  source = "github.com/raymondbutcher/terraform-archive-stable?ref=v0.0.4"

  enabled = var.enabled && var.build_mode != "DISABLED"

  empty_dirs  = var.empty_dirs
  output_path = var.enabled && var.build_mode == "FILENAME" ? var.filename : var.enabled && var.build_mode != "DISABLED" ? "${path.module}/zip_files/${data.aws_partition.current[0].partition}-${data.aws_region.current[0].name}-${data.aws_caller_identity.current[0].account_id}-${var.function_name}.zip" : ""
  source_dir  = var.source_dir
}

############################################
# Upload the zip file to S3                #
# (if build mode is CODEBUILD, LAMBDA, S3) #
############################################

resource "aws_s3_bucket_object" "source_zip_file" {
  count = var.enabled && contains(["CODEBUILD", "LAMBDA", "S3"], var.build_mode) ? 1 : 0

  bucket = var.s3_bucket
  key    = contains(["CODEBUILD", "LAMBDA"], var.build_mode) ? "${var.function_name}/${module.source_zip_file.output_sha}/source.zip" : var.s3_key
  source = module.source_zip_file.output_path

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  source_zip_file_s3_key = var.enabled && contains(["CODEBUILD", "LAMBDA", "S3"], var.build_mode) ? aws_s3_bucket_object.source_zip_file[0].key : null
}

###############################################
# Build the final package with CloudFormation #
# (if build mode is CODEBUILD, LAMBDA)        #
###############################################

locals {
  cloudformation_parameters = {
    Bucket    = var.s3_bucket
    KeyPrefix = var.function_name
    KeySource = local.source_zip_file_s3_key
  }
  codebuild_cloudformation_template_body = var.enabled && var.build_mode == "CODEBUILD" ? templatefile("${path.module}/codebuild_builder/cfn.yaml.tmpl", {
    codebuild_environment_compute_type  = var.codebuild_environment_compute_type
    codebuild_environment_image         = var.codebuild_environment_image
    codebuild_environment_type          = var.codebuild_environment_type
    codebuild_queued_timeout_in_minutes = var.codebuild_queued_timeout_in_minutes
    codebuild_timeout_in_minutes        = var.codebuild_timeout_in_minutes
    lambda_builder_code                 = file("${path.module}/codebuild_builder/lambda.py")
    lambda_builder_handler              = "index.handler"
    lambda_builder_memory_size          = 128
    lambda_builder_runtime              = "python3.7"
    lambda_builder_timeout              = 60
  }) : null
  lambda_builder_filenames = {
    "nodejs10.x" = "nodejs.js"
    "nodejs12.x" = "nodejs.js"
    "nodejs14.x" = "nodejs.js"
    "python2.7"  = "python.py"
    "python3.6"  = "python.py"
    "python3.7"  = "python.py"
  }
  lambda_cloudformation_template_body = var.enabled && var.build_mode == "LAMBDA" ? templatefile("${path.module}/lambda_builders/cfn.yaml.tmpl", {
    lambda_builder_code        = file("${path.module}/lambda_builders/${local.lambda_builder_filenames[var.runtime]}")
    lambda_builder_handler     = "index.handler"
    lambda_builder_memory_size = var.lambda_builder_memory_size
    lambda_builder_timeout     = var.lambda_builder_timeout
    lambda_runtime             = var.runtime
  }) : null
  cloudformation_template_body = coalesce(local.codebuild_cloudformation_template_body, local.lambda_cloudformation_template_body, "unused")
}

# Create a random build_id that changes when the source zip
# or CloudFormation details changes.

resource "random_string" "build_id" {
  count = var.enabled && contains(["CODEBUILD", "LAMBDA"], var.build_mode) ? 1 : 0

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
  count = var.enabled && contains(["CODEBUILD", "LAMBDA"], var.build_mode) ? 1 : 0

  name         = "${var.s3_bucket}-${random_string.build_id[0].result}"
  capabilities = ["CAPABILITY_IAM"]
  on_failure   = "DELETE"

  parameters = merge(local.cloudformation_parameters, {
    KeyTarget     = "${var.function_name}/${module.source_zip_file.output_sha}/${random_string.build_id[0].result}.zip"
    KeyTargetName = "${random_string.build_id[0].result}.zip"
    KeyTargetPath = "${var.function_name}/${module.source_zip_file.output_sha}"
  })

  template_body = local.cloudformation_template_body

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  built_s3_key = var.enabled && contains(["CODEBUILD", "LAMBDA"], var.build_mode) ? aws_cloudformation_stack.builder[0].outputs.Key : null
}

#######################################
# Create an IAM role for the function #
# (if role is not supplied)           #
#######################################

module "role" {
  source = "git::https://gitlab.com/claranet-pcp/terraform/aws/terraform-aws-lambda-role.git?ref=v0.1.0"

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
  s3_key                         = contains(["CODEBUILD", "LAMBDA", "S3"], var.build_mode) ? coalesce(local.built_s3_key, local.source_zip_file_s3_key) : var.s3_key
  s3_object_version              = var.s3_object_version
  source_code_hash               = contains(["FILENAME", "S3"], var.build_mode) ? module.source_zip_file.output_base64sha256 : var.source_code_hash
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
