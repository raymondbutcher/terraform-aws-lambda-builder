from pretf.api import block
from pretf.collections import collect


def pretf_blocks(path):
    function_names = []
    for version in ("3.6", "3.7"):
        python_lambda = yield python_lambda_resources(version=version)
        function_names.append(python_lambda.function_name)
    yield block("output", "function_names", {"value": function_names})


@collect
def python_lambda_resources(var):

    yield block("variable", "version", {})

    label = f"python_{var.version.replace('.', '')}"
    runtime = f"python{var.version}"

    random = yield block(
        "resource",
        "random_id",
        label,
        {"prefix": f"terraform-aws-lambda-builder-tests-{label}-", "byte_length": 8},
    )

    role = yield block(
        "module",
        f"{label}_role",
        {
            "source": "git::https://gitlab.com/claranet-pcp/terraform/aws/terraform-aws-lambda-role.git?ref=v0.0.1",
            "function_name": random.hex,
            "cloudwatch_logs": True,
        },
    )

    func = yield block(
        "module",
        f"{label}_lambda",
        {
            "source": "../../",
            "build_mode": "LAMBDA",
            "create_role": False,
            "function_name": random.hex,
            "handler": "lambda.handler",
            "role": role.arn,
            "runtime": runtime,
            "s3_bucket": block("aws_s3_bucket", "packages", {}).id,
            "source_dir": "./src",
            "timeout": 30,
        },
    )

    yield block("output", "function_name", {"value": func.function_name})
