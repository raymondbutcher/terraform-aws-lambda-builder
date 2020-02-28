output "arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function."
  value       = var.enabled ? aws_lambda_function.built[0].arn : null
}

output "dead_letter_config" {
  description = "The function's dead letter queue configuration."
  value       = var.enabled ? aws_lambda_function.built[0].dead_letter_config : null
}

output "description" {
  description = "Description of what your Lambda Function does."
  value       = var.enabled ? aws_lambda_function.built[0].description : null
}

output "environment" {
  description = "The Lambda environment's configuration settings."
  value       = var.enabled ? aws_lambda_function.built[0].environment : null
}

output "function_name" {
  description = "The unique name for your Lambda Function."
  value       = var.enabled ? aws_lambda_function.built[0].function_name : null
}

output "handler" {
  description = "The function entrypoint in your code."
  value       = var.enabled ? aws_lambda_function.built[0].handler : null
}

output "kms_key_arn" {
  description = "The ARN for the KMS encryption key."
  value       = var.enabled ? aws_lambda_function.built[0].kms_key_arn : null
}

output "layers" {
  description = "List of Lambda Layer Version ARNs attached to your Lambda Function."
  value       = var.enabled ? aws_lambda_function.built[0].layers : null
}

output "last_modified" {
  description = "The date this resource was last modified."
  value       = var.enabled ? aws_lambda_function.built[0].last_modified : null
}

output "log_group_name" {
  description = "The log group name for your Lambda Function."
  value       = var.enabled ? "/aws/lambda/${aws_lambda_function.built[0].function_name}" : null
}

output "log_group_name_edge" {
  description = "The log group name for your Lambda@Edge Function."
  value       = var.enabled ? "/aws/lambda/us-east-1.${aws_lambda_function.built[0].function_name}" : null
}

output "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime."
  value       = var.enabled ? aws_lambda_function.built[0].memory_size : null
}

output "qualified_arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function Version (if versioning is enabled via publish = true)."
  value       = var.enabled ? aws_lambda_function.built[0].qualified_arn : null
}

output "invoke_arn" {
  description = "The ARN to be used for invoking Lambda Function from API Gateway."
  value       = var.enabled ? aws_lambda_function.built[0].invoke_arn : null
}

output "publish" {
  description = "Whether creation/changes will publish a new Lambda Function Version."
  value       = var.enabled ? aws_lambda_function.built[0].publish : null
}

output "reserved_concurrent_executions" {
  description = "The amount of reserved concurrent executions for this lambda function."
  value       = var.enabled ? aws_lambda_function.built[0].reserved_concurrent_executions : null
}

output "role" {
  description = "IAM role attached to the Lambda Function."
  value       = var.enabled ? aws_lambda_function.built[0].role : null
}

output "role_name" {
  description = "The name of the IAM role attached to the Lambda Function."
  value       = var.enabled ? element(split("/", aws_lambda_function.built[0].role), 1) : null
}

output "runtime" {
  description = "The identifier of the function's runtime."
  value       = var.enabled ? aws_lambda_function.built[0].runtime : null
}

output "s3_bucket" {
  description = "The S3 bucket location containing the function's deployment package."
  value       = var.enabled ? aws_lambda_function.built[0].s3_bucket : null
}

output "s3_key" {
  description = "The S3 key of an object containing the function's deployment package."
  value       = var.enabled ? aws_lambda_function.built[0].s3_key : null
}

output "s3_object_version" {
  description = "The object version containing the function's deployment package."
  value       = var.enabled ? aws_lambda_function.built[0].s3_object_version : null
}

output "source_code_hash" {
  description = "Base64-encoded representation of raw SHA-256 sum of the zip file."
  value       = var.enabled ? aws_lambda_function.built[0].source_code_hash : null
}

output "source_code_size" {
  description = "The size in bytes of the function .zip file."
  value       = var.enabled ? aws_lambda_function.built[0].source_code_size : null
}

output "tags" {
  description = "A mapping of tags assigned to the object."
  value       = var.enabled ? aws_lambda_function.built[0].tags : null
}

output "timeout" {
  description = "The amount of time your Lambda Function has to run in seconds."
  value       = var.enabled ? aws_lambda_function.built[0].timeout : null
}

output "tracing_config" {
  description = "The tracing configuration."
  value       = var.enabled ? aws_lambda_function.built[0].tracing_config : null
}

output "version" {
  description = "Latest published version of your Lambda Function."
  value       = var.enabled ? aws_lambda_function.built[0].version : null
}

output "vpc_config" {
  description = "The VPC configuration."
  value       = var.enabled ? aws_lambda_function.built[0].vpc_config : null
}
