data "aws_caller_identity" "current" {
  count = var.enabled && (var.build_mode == "LAMBDA" || var.build_mode == "S3") ? 1 : 0
}

data "aws_partition" "current" {
  count = var.enabled && (var.build_mode == "LAMBDA" || var.build_mode == "S3") ? 1 : 0
}

data "aws_region" "current" {
  count = var.enabled && (var.build_mode == "LAMBDA" || var.build_mode == "S3") ? 1 : 0
}
