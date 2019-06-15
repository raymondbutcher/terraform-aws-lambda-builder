module "role" {
  source = "git::https://gitlab.com/claranet-pcp/terraform/aws/terraform-aws-lambda-role.git?ref=v0.0.4"

  enabled = var.enabled && var.role == null

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
