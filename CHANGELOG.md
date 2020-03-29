# terraform-aws-lambda-builder changes

## v1.0.0

### Added

* New `build_mode` value `CODEBUILD` with example using the `go1.x` runtime.

### Breaking changes

* `builder_memory_size` renamed to `lambda_builder_memory_size`.
* `builder_timeout` renamed to `lambda_builder_timeout`.
