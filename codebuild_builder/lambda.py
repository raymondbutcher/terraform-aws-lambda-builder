import json

import boto3
import cfnresponse

codebuild_client = boto3.client("codebuild")
s3_client = boto3.client("s3")


def handler(event, context):
    physical_resource_id = None
    codebuild_running = False
    try:

        if event.get("RequestType") in ("Create", "Update"):

            bucket = event["ResourceProperties"]["Bucket"]
            key_target = event["ResourceProperties"]["KeyTarget"]
            physical_resource_id = f"arn:aws:s3:::{bucket}/{key_target}"

            start_build(event)
            codebuild_running = True

        elif event.get("source") == "aws.codebuild":

            codebuild_status = event["detail"]["build-status"]

            # Replace event with original event, will be used by cfnresponse.
            env = event["detail"]["additional-information"]["environment"][
                "environment-variables"
            ]
            for var in env:
                if var["name"] == "CFN_EVENT":
                    event = json.loads(var["value"])
                    break
            else:
                raise ValueError(env)

            bucket = event["ResourceProperties"]["Bucket"]
            key_target = event["ResourceProperties"]["KeyTarget"]
            physical_resource_id = f"arn:aws:s3:::{bucket}/{key_target}"

            if codebuild_status != "SUCCEEDED":
                raise ValueError(codebuild_status)

            # Ensure zip was uploaded (must be in buildspec).
            s3_client.head_object(Bucket=bucket, Key=key_target)

            # Delete previous zip after updates.
            if event["RequestType"] == "Update":
                old_physical_resource_id = event["PhysicalResourceId"]
                if old_physical_resource_id != physical_resource_id:
                    delete(old_physical_resource_id)

        elif event.get("RequestType") == "Delete":

            physical_resource_id = event["PhysicalResourceId"]
            delete(physical_resource_id)

            bucket = event["ResourceProperties"]["Bucket"]
            key_target = event["ResourceProperties"]["KeyTarget"]
            delete(f"arn:aws:s3:::{bucket}/{key_target}")

        else:

            raise ValueError(event)

        status = cfnresponse.SUCCESS

    except Exception:

        status = cfnresponse.FAILED

        print(event)

        raise

    finally:

        if not codebuild_running:
            response_data = {}
            cfnresponse.send(
                event, context, status, response_data, physical_resource_id
            )


def start_build(event):

    env = {}

    bucket = event["ResourceProperties"]["Bucket"]
    key_target = event["ResourceProperties"]["KeyTarget"]

    env["TARGET_BUCKET"] = bucket
    env["TARGET_KEY"] = key_target
    env["TARGET_URL"] = f"s3://{bucket}/{key_target}"

    env["CFN_EVENT"] = json.dumps(event)

    response = codebuild_client.start_build(
        projectName=event["ResourceProperties"]["CodeBuildProjectName"],
        environmentVariablesOverride=[
            {"name": key, "value": value} for (key, value) in env.items()
        ],
    )
    print(response)


def delete(physical_resource_id):
    if physical_resource_id.startswith("arn:aws:s3:::"):
        bucket_and_key = physical_resource_id.split(":")[-1]
        bucket, key = bucket_and_key.split("/", 1)
        s3_client.delete_object(Bucket=bucket, Key=key)
