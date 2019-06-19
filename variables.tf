# Builder arguments.

variable "build_mode" {
  description = "The build mode to use, one of `DISABLED`, `FILENAME`, `LAMBDA`, `S3`."
  type        = string
  default     = "DISABLED"
}

variable "builder_memory_size" {
  description = "Memory size for the builder Lambda function."
  type        = number
  default     = 128
}

variable "builder_timeout" {
  description = "Timeout for the builder Lambda function."
  type        = number
  default     = 900
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
  type = object({
    target_arn = string
  })
  default = null
}

variable "description" {
  type    = string
  default = null
}

variable "environment" {
  type = object({
    variables = map(string)
  })
  default = null
}

variable "filename" {
  type    = string
  default = null
}

variable "function_name" {
  type = string
}

variable "handler" {
  type = string
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "layers" {
  type    = list(string)
  default = null
}

variable "memory_size" {
  type    = number
  default = null
}

variable "publish" {
  type    = bool
  default = null
}

variable "reserved_concurrent_executions" {
  type    = number
  default = null
}

variable "role" {
  type    = string
  default = null
}

variable "runtime" {
  type = string
}

variable "s3_bucket" {
  type    = string
  default = null
}

variable "s3_key" {
  type    = string
  default = null
}

variable "s3_object_version" {
  type    = string
  default = null
}

variable "source_code_hash" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = null
}

variable "timeout" {
  type    = number
  default = null
}

variable "tracing_config" {
  type = object({
    mode = string
  })
  default = null
}

variable "vpc_config" {
  type = object({
    security_group_ids = list(string)
    subnet_ids         = list(string)
  })
  default = null
}
