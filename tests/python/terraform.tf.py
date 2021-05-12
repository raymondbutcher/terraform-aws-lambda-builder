from pretf.aws import terraform_backend_s3


def pretf_blocks():
    yield terraform_backend_s3(
        bucket="terraform-aws-lambda-builder",
        dynamodb_table="terraform-aws-lambda-builder",
        key="python.tfstate",
        profile="rbutcher",
        region="eu-west-1",
    )
