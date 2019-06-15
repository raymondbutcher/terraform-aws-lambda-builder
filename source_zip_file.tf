module "source_zip_file" {
  source = "github.com/raymondbutcher/terraform-archive-stable?ref=v0.0.3"

  enabled = var.enabled && var.build_mode != null

  empty_dirs  = var.empty_dirs
  output_path = "${path.module}/zip_files/${data.aws_partition.current[0].partition}-${data.aws_region.current[0].name}-${data.aws_caller_identity.current[0].account_id}-${var.function_name}.zip"
  source_dir  = var.source_dir
}

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
