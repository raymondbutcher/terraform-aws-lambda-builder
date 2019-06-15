import io
import os
import shutil
import zipfile

import boto3

import cfnresponse

s3_client = boto3.client("s3")


def handler(event, context):
    physical_resource_id = None
    try:

        bucket = event["ResourceProperties"]["Bucket"]
        key_target = event["ResourceProperties"]["KeyTarget"]
        arn = "arn:aws:s3:::{}/{}".format(bucket, key_target)
        physical_resource_id = arn

        if event["RequestType"] == "Create":

            build(event)

        elif event["RequestType"] == "Update":

            build(event)

            old_physical_resource_id = event["PhysicalResourceId"]

            if physical_resource_id != old_physical_resource_id:
                delete(old_physical_resource_id)

        elif event["RequestType"] == "Delete":

            physical_resource_id = event["PhysicalResourceId"]

            delete(physical_resource_id)

        else:

            raise ValueError(event["RequestType"])

        status = cfnresponse.SUCCESS

    except Exception:

        status = cfnresponse.FAILED

        raise

    finally:
        response_data = {}
        cfnresponse.send(event, context, status, response_data, physical_resource_id)


def build(event):

    bucket = event["ResourceProperties"]["Bucket"]
    key_source = event["ResourceProperties"]["KeySource"]
    key_target = event["ResourceProperties"]["KeyTarget"]

    # Download the source zip.
    download_path = "/tmp/source.zip"
    print("Downloading s3://{}/{} to {}".format(bucket, key_source, download_path))
    s3_client.download_file(bucket, key_source, download_path)

    # Extract the source zip.
    build_path = "/tmp/build"
    print("Prepating build path {}".format(build_path))
    if os.path.exists(build_path):
        shutil.rmtree(build_path)
    os.mkdir(build_path)
    os.chdir(build_path)

    # Extract the source zip.
    print("Extracting {} to {}".format(download_path, build_path))
    with zipfile.ZipFile(download_path, "r") as archive:
        archive.extractall()
    os.remove(download_path)

    # Run the build script from the zip.
    print("Running build script")
    os.chmod("./build.sh", 0o755)
    exit_status = os.system("./build.sh")
    if exit_status != 0:
        raise ValueError(exit_status)

    # Zip up the directory and then upload it.
    with io.BytesIO() as zip_buffer:

        print("Zipping {}".format(build_path))
        with zipfile.ZipFile(zip_buffer, "a") as zip_file:
            for root, sub_dirs, files in os.walk(build_path):
                for file_name in files:
                    absolute_path = os.path.join(root, file_name)
                    relative_path = os.path.relpath(absolute_path, build_path)
                    zip_file.write(absolute_path, relative_path)
        zip_buffer.seek(0)

        print("Uploading zip to s3://{}/{}".format(bucket, key_target))
        s3_client.put_object(Bucket=bucket, Key=key_target, Body=zip_buffer)


def delete(physical_resource_id):

    # The custom resource identifier is an S3 object ARN.
    # Extract the bucket and key from it.
    arn = physical_resource_id
    bucket_and_key = arn.split(":")[-1]
    bucket, key = bucket_and_key.split("/", 1)

    # Delete the S3 object.
    print("Deleting s3://{}/{}".format(bucket, key))
    s3_client.delete_object(Bucket=bucket, Key=key)
