# Builder arguments.

variable "build_mode" {
  description = "The build mode to use, one of `CODEBUILD`, `DISABLED`, `FILENAME`, `LAMBDA`, `S3`."
  type        = string
  default     = "DISABLED"
}

variable "codebuild_environment_compute_type" {
  description = "Compute type for CodeBuild. See https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "codebuild_environment_image" {
  description = "Image for CodeBuild. See https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html"
  type        = string
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
}

variable "codebuild_environment_type" {
  description = "The type of CodeBuild build environment to use. See https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html"
  default     = "LINUX_CONTAINER"
}

variable "codebuild_queued_timeout_in_minutes" {
  description = "The number of minutes CodeBuild is allowed to be queued before it times out."
  type        = number
  default     = 15
}

variable "codebuild_timeout_in_minutes" {
  description = "The number of minutes CodeBuild is allowed to run before it times out."
  type        = number
  default     = 60
}

variable "create_role" {
  description = "Create an IAM role for the function. Only required when `role` is a computed/unknown value."
  type        = bool
  default     = null
}

variable "enable_input_validation" {
  description = "Check validity of input variables."
  type        = bool
  default     = true
}

variable "empty_dirs" {
  description = "Include empty directories in the Lambda package."
  type        = bool
  default     = false
}

variable "enabled" {
  description = "Create resources."
  type        = bool
  default     = true
}

variable "lambda_builder_memory_size" {
  description = "Memory size for the builder Lambda function."
  type        = number
  default     = 512
}

variable "lambda_builder_timeout" {
  description = "Timeout for the builder Lambda function."
  type        = number
  default     = 900
}

variable "role_cloudwatch_logs" {
  description = "If `role` is not provided, one will be created with a policy that enables CloudWatch Logs."
  type        = bool
  default     = false
}

variable "role_custom_policies" {
  description = "If `role` is not provided, one will be created with these JSON policies attached."
  type        = list(string)
  default     = []
}

variable "role_custom_policies_count" {
  description = "The number of `role_custom_policies` to attach. Only required when `role_custom_policies` is a computed/unknown value."
  type        = number
  default     = null
}

variable "role_policy_arns" {
  description = "If `role` is not provided, one will be created with these policy ARNs attached."
  type        = list(string)
  default     = []
}

variable "role_policy_arns_count" {
  description = "The number of `role_policy_arns` to attach. Only required when `role_policy_arns` is a computed/unknown value."
  type        = number
  default     = null
}

variable "source_dir" {
  description = "Local source directory for the Lambda package. This will be zipped and uploaded to the S3 bucket. Requires `s3_bucket`. Conflicts with `s3_key`, `s3_object_version` and `filename`."
  type        = string
  default     = ""
}

# Standard Lambda resource arguments.

variable "dead_letter_config" {
  description = "Nested block to configure the function's dead letter queue. See details below."
  type = object({
    target_arn = string
  })
  default = null
}

variable "description" {
  description = "Description of what your Lambda Function does."
  type        = string
  default     = null
}

variable "environment" {
  description = "The Lambda environment's configuration settings."
  type = object({
    variables = map(string)
  })
  default = null
}

variable "filename" {
  description = "The path to the function's deployment package within the local filesystem. If defined, The s3_-prefixed options cannot be used."
  type        = string
  default     = null
}

variable "function_name" {
  description = "A unique name for your Lambda Function."
  type        = string
}

variable "handler" {
  description = "The function entrypoint in your code."
  type        = string
}

variable "kms_key_arn" {
  description = "Amazon Resource Name (ARN) of the AWS Key Management Service (KMS) key that is used to encrypt environment variables."
  type        = string
  default     = null
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function."
  type        = list(string)
  default     = null
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime."
  type        = number
  default     = null
}

variable "publish" {
  description = "Whether to publish creation/change as new Lambda Function Version."
  type        = bool
  default     = null
}

variable "reserved_concurrent_executions" {
  description = "The amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations."
  type        = number
  default     = null
}

variable "role" {
  description = "IAM role attached to the Lambda Function. This governs both who / what can invoke your Lambda Function, as well as what resources our Lambda Function has access to."
  type        = string
  default     = null
}

variable "runtime" {
  description = "The identifier of the function's runtime."
  type        = string
}

variable "s3_bucket" {
  description = "The S3 bucket location containing the function's deployment package. Conflicts with filename. This bucket must reside in the same AWS region where you are creating the Lambda function."
  type        = string
  default     = null
}

variable "s3_key" {
  description = "The S3 key of an object containing the function's deployment package. Conflicts with filename."
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "The object version containing the function's deployment package. Conflicts with filename."
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Used to trigger updates. Must be set to a base64-encoded SHA256 hash of the package file specified with either filename or s3_key."
  type        = string
  default     = null
}

variable "tags" {
  description = "A mapping of tags to assign to the object."
  type        = map(string)
  default     = null
}

variable "timeout" {
  description = "The amount of time your Lambda Function has to run in seconds."
  type        = number
  default     = null
}

variable "tracing_config" {
  description = "Provide this to configure tracing."
  type = object({
    mode = string
  })
  default = null
}

variable "vpc_config" {
  description = "Provide this to allow your function to access your VPC."
  type = object({
    security_group_ids = list(string)
    subnet_ids         = list(string)
  })
  default = null
}
