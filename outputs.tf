output "hash" {
  value = var.enabled ? aws_lambda_function.built[0].source_code_hash : null
}

output "arn" {
  value = var.enabled ? aws_lambda_function.built[0].arn : null
}

output "dead_letter_config" {
  value = var.enabled ? aws_lambda_function.built[0].dead_letter_config : null
}

output "description" {
  value = var.enabled ? aws_lambda_function.built[0].description : null
}

output "environment" {
  value = var.enabled ? aws_lambda_function.built[0].environment : null
}

output "function_name" {
  value = var.enabled ? aws_lambda_function.built[0].function_name : null
}

output "handler" {
  value = var.enabled ? aws_lambda_function.built[0].handler : null
}

output "kms_key_arn" {
  value = var.enabled ? aws_lambda_function.built[0].kms_key_arn : null
}

output "layers" {
  value = var.enabled ? aws_lambda_function.built[0].layers : null
}

output "last_modified" {
  value = var.enabled ? aws_lambda_function.built[0].last_modified : null
}

output "log_group_name" {
  value = var.enabled ? "/aws/lambda/${aws_lambda_function.built[0].function_name}" : null
}

output "log_group_name_edge" {
  value = var.enabled ? "/aws/lambda/us-east-1.${aws_lambda_function.built[0].function_name}" : null
}

output "memory_size" {
  value = var.enabled ? aws_lambda_function.built[0].memory_size : null
}

output "qualified_arn" {
  value = var.enabled ? aws_lambda_function.built[0].qualified_arn : null
}

output "invoke_arn" {
  value = var.enabled ? aws_lambda_function.built[0].invoke_arn : null
}

output "publish" {
  value = var.enabled ? aws_lambda_function.built[0].publish : null
}

output "reserved_concurrent_executions" {
  value = var.enabled ? aws_lambda_function.built[0].reserved_concurrent_executions : null
}

output "role" {
  value = var.enabled ? aws_lambda_function.built[0].role : null
}

output "role_name" {
  value = var.enabled ? element(split("/", aws_lambda_function.built[0].role), 1) : null
}

output "runtime" {
  value = var.enabled ? aws_lambda_function.built[0].runtime : null
}

output "s3_bucket" {
  value = var.enabled ? aws_lambda_function.built[0].s3_bucket : null
}

output "s3_key" {
  value = var.enabled ? aws_lambda_function.built[0].s3_key : null
}

output "s3_object_version" {
  value = var.enabled ? aws_lambda_function.built[0].s3_object_version : null
}

output "source_code_hash" {
  value = var.enabled ? aws_lambda_function.built[0].source_code_hash : null
}

output "source_code_size" {
  value = var.enabled ? aws_lambda_function.built[0].source_code_size : null
}

output "tags" {
  value = var.enabled ? aws_lambda_function.built[0].tags : null
}

output "timeout" {
  value = var.enabled ? aws_lambda_function.built[0].timeout : null
}

output "tracing_config" {
  value = var.enabled ? aws_lambda_function.built[0].tracing_config : null
}

output "version" {
  value = var.enabled ? aws_lambda_function.built[0].version : null
}

output "vpc_config" {
  value = var.enabled ? aws_lambda_function.built[0].vpc_config : null
}
