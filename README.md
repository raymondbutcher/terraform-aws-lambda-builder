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
  function_name = "example"
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

See the [tests](tests) directory for more working examples.

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
| nodejs10.x | `npm install` works  |
| nodejs12.x | `npm install` works  |
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

<!--
The Inputs and Outputs sections below are automatically generated
in the master branch, so don't bother manually changing them.
-->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| create\_role | Create an IAM role for the function. Only required when `role` is a computed/unknown value. | `bool` | n/a | yes |
| dead\_letter\_config | Nested block to configure the function's dead letter queue. See details below. | <pre>object({<br>    target_arn = string<br>  })<br></pre> | n/a | yes |
| description | Description of what your Lambda Function does. | `string` | n/a | yes |
| environment | The Lambda environment's configuration settings. | <pre>object({<br>    variables = map(string)<br>  })<br></pre> | n/a | yes |
| filename | The path to the function's deployment package within the local filesystem. If defined, The s3\_-prefixed options cannot be used. | `string` | n/a | yes |
| function\_name | A unique name for your Lambda Function. | `string` | n/a | yes |
| handler | The function entrypoint in your code. | `string` | n/a | yes |
| kms\_key\_arn | Amazon Resource Name (ARN) of the AWS Key Management Service (KMS) key that is used to encrypt environment variables. | `string` | n/a | yes |
| layers | List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function. | `list(string)` | n/a | yes |
| memory\_size | Amount of memory in MB your Lambda Function can use at runtime. | `number` | n/a | yes |
| publish | Whether to publish creation/change as new Lambda Function Version. | `bool` | n/a | yes |
| reserved\_concurrent\_executions | The amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations. | `number` | n/a | yes |
| role | IAM role attached to the Lambda Function. This governs both who / what can invoke your Lambda Function, as well as what resources our Lambda Function has access to. | `string` | n/a | yes |
| role\_custom\_policies\_count | The number of `role_custom_policies` to attach. Only required when `role_custom_policies` is a computed/unknown value. | `number` | n/a | yes |
| role\_policy\_arns\_count | The number of `role_policy_arns` to attach. Only required when `role_policy_arns` is a computed/unknown value. | `number` | n/a | yes |
| runtime | The identifier of the function's runtime. | `string` | n/a | yes |
| s3\_bucket | The S3 bucket location containing the function's deployment package. Conflicts with filename. This bucket must reside in the same AWS region where you are creating the Lambda function. | `string` | n/a | yes |
| s3\_key | The S3 key of an object containing the function's deployment package. Conflicts with filename. | `string` | n/a | yes |
| s3\_object\_version | The object version containing the function's deployment package. Conflicts with filename. | `string` | n/a | yes |
| source\_code\_hash | Used to trigger updates. Must be set to a base64-encoded SHA256 hash of the package file specified with either filename or s3\_key. | `string` | n/a | yes |
| tags | A mapping of tags to assign to the object. | `map(string)` | n/a | yes |
| timeout | The amount of time your Lambda Function has to run in seconds. | `number` | n/a | yes |
| tracing\_config | Provide this to configure tracing. | <pre>object({<br>    mode = string<br>  })<br></pre> | n/a | yes |
| vpc\_config | Provide this to allow your function to access your VPC. | <pre>object({<br>    security_group_ids = list(string)<br>    subnet_ids         = list(string)<br>  })<br></pre> | n/a | yes |
| build\_mode | The build mode to use, one of `DISABLED`, `FILENAME`, `LAMBDA`, `S3`. | `string` | `"DISABLED"` | no |
| builder\_memory\_size | Memory size for the builder Lambda function. | `number` | `512` | no |
| builder\_timeout | Timeout for the builder Lambda function. | `number` | `900` | no |
| empty\_dirs | Include empty directories in the Lambda package. | `bool` | `false` | no |
| enabled | Create resources. | `bool` | `true` | no |
| role\_cloudwatch\_logs | If `role` is not provided, one will be created with a policy that enables CloudWatch Logs. | `bool` | `false` | no |
| role\_custom\_policies | If `role` is not provided, one will be created with these JSON policies attached. | `list(string)` | `[]` | no |
| role\_policy\_arns | If `role` is not provided, one will be created with these policy ARNs attached. | `list(string)` | `[]` | no |
| source\_dir | Local source directory for the Lambda package. This will be zipped and uploaded to the S3 bucket. Requires `s3_bucket`. Conflicts with `s3_key`, `s3_object_version` and `filename`. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| arn | The Amazon Resource Name (ARN) identifying your Lambda Function. |
| dead\_letter\_config | The function's dead letter queue configuration. |
| description | Description of what your Lambda Function does. |
| environment | The Lambda environment's configuration settings. |
| function\_name | The unique name for your Lambda Function. |
| handler | The function entrypoint in your code. |
| invoke\_arn | The ARN to be used for invoking Lambda Function from API Gateway. |
| kms\_key\_arn | The ARN for the KMS encryption key. |
| last\_modified | The date this resource was last modified. |
| layers | List of Lambda Layer Version ARNs attached to your Lambda Function. |
| log\_group\_name | The log group name for your Lambda Function. |
| log\_group\_name\_edge | The log group name for your Lambda@Edge Function. |
| memory\_size | Amount of memory in MB your Lambda Function can use at runtime. |
| publish | Whether creation/changes will publish a new Lambda Function Version. |
| qualified\_arn | The Amazon Resource Name (ARN) identifying your Lambda Function Version (if versioning is enabled via publish = true). |
| reserved\_concurrent\_executions | The amount of reserved concurrent executions for this lambda function. |
| role | IAM role attached to the Lambda Function. |
| role\_name | The name of the IAM role attached to the Lambda Function. |
| runtime | The identifier of the function's runtime. |
| s3\_bucket | The S3 bucket location containing the function's deployment package. |
| s3\_key | The S3 key of an object containing the function's deployment package. |
| s3\_object\_version | The object version containing the function's deployment package. |
| source\_code\_hash | Base64-encoded representation of raw SHA-256 sum of the zip file. |
| source\_code\_size | The size in bytes of the function .zip file. |
| tags | A mapping of tags assigned to the object. |
| timeout | The amount of time your Lambda Function has to run in seconds. |
| tracing\_config | The tracing configuration. |
| version | Latest published version of your Lambda Function. |
| vpc\_config | The VPC configuration. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
