# terraform-aws-lambda-builder

This Terraform module packages and deploys an AWS Lambda function. It optionally runs a build script *inside Lambda* to build the Lambda package.

## Features

* Supports `source_dir` to automatically create Lambda packages.
    * Handles source code changes automatically and correctly.
    * No unexpected changes in Terraform plans.
* Supports `LAMBDA build_mode` to run a build scripts inside Lambda.
    * Define your own build script with shell commands like `pip install`, `npm install`, etc.
    * Runs inside Lambda using the same runtime environment as the target Lambda function.
    * No reliance on `pip`, `virtualenv`, `npm`, etc on the machine running Terraform.
    * Smaller zip files to upload because `pip install`, etc. doesn't run locally.
* Supports `S3/FILENAME build_mode` to just get the zip functionality.
    * For when there are no build steps but you still want the `source_dir` functionality.
* Helps you to avoid:
    * Separate build steps to create packages before running Terraform.
    * Committing built package zip files to version control.

## Requirements

* Python

Python is used to create deterministic zip files. Terraform's `archive_file` data source is not used because it sometimes [produces different results](https://github.com/terraform-providers/terraform-provider-archive/issues/34) which lead to spurious resource changes when working in teams.

## Example

```terraform
module "lambda_function" {
  source = "github.com/raymondbutcher/terraform-aws-lambda-builder"

  # Standard aws_lambda_function attributes.
  function_name = module.lambda_role.function_name
  handler       = "lambda.handler"
  runtime       = "python3.6"
  s3_bucket     = aws_s3_bucket.packages.id
  timeout       = 30

  # Enable build functionality.
  build_mode = "LAMBDA"
  source_dir = "${path.module}/src"

  # Create and use a role with CloudWatch Logs permissions.
  role_cloudwatch_logs = true
}
```

## Build modes

The `build_mode` input variable can be set to one of:

* `LAMBDA`
    * Zips `source_dir`, uploads it to `s3_bucket` and runs `build.sh` inside Lambda to build the final package.
* `S3`
    * Zips `source_dir` and uploads to `s3_bucket` at `s3_key`.
* `FILENAME`
    * Zips `source_dir` and uploads it directly to the Lambda service.
* `DISABLED` (default)
    * Disables build functionality.

### Lambda build mode

If running in `LAMBDA` build mode, then this module will run `build.sh` from `source_dir` inside the target Lambda runtime environment, and then create a new package for the final Lambda function to use.

The `LAMBDA` build mode works as follows.

* Terraform runs [zip.py](https://github.com/raymondbutcher/terraform-archive-stable) which:
    * Creates a zip file from the source directory.
    * Timestamps and permissions are normalised so the resulting file hash is consistent and only affected by meaningful changes.
* Terraform uploads the zip file to the S3 bucket.
* Terraform creates a CloudFormation stack which:
    * Creates a custom resource Lambda function which:
        * Downloads the zip file from the S3 bucket.
        * Extracts the zip file.
        * Runs the build script.
        * Creates a new zip file.
        * Uploads it to the S3 bucket in another location.
    * Outputs the location of the new zip file for Terraform to use.
* Terraform creates a Lambda function using the new zip file.

 Different runtimes have different tools installed. Here are some notes about what is available to use in `build.sh`.

| Runtime    | Notes                |
|------------|----------------------|
| nodejs8.10 | `npm install` works  |
| python2.7  | `pip` not included   |
| python3.6  | `pip install` works  |
| python3.7  | `pip install` works  |

Runtimes not listed above have not been tested.

### S3 build mode

The `S3` build mode zips `source_dir` and uploads it to S3 using `s3_bucket` and `s3_key`. It automatically sets `source_code_hash` to ensure changes to the source code get deployed.

### Filename build mode

The `FILENAME` build mode zips `source_dir` and writes it to `filename`. The package is uploaded directly to the Lambda service. It automatically sets `source_code_hash` to ensure changes to the source code get deployed.

### Disabled build mode

The `DISABLED` build mode disables build functionality, making this module do nothing except create a Lambda function resource and optionally its IAM role.

## Automatic role creation

If a `role` is not provided then one will be created automatically. There are various input variables which add policies to this role. If `dead_letter_config` or `vpc_config` are set, then the required policies are automatically attached to this role.
