data "external" "validate" {
  count = var.enabled ? 1 : 0

  program = ["python", "${path.module}/validate.py"]
  query = {
    build_mode        = var.build_mode != null ? var.build_mode : ""
    filename          = var.filename != null ? var.filename : ""
    s3_bucket         = var.s3_bucket != null ? var.s3_bucket : ""
    s3_key            = var.s3_key != null ? var.s3_key : ""
    s3_object_version = var.s3_object_version != null ? var.s3_object_version : ""
    source_code_hash  = var.source_code_hash != null ? var.source_code_hash : ""
    source_dir        = var.source_dir != null ? var.source_dir : ""
  }
}