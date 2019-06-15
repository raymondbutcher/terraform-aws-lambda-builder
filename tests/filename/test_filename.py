import json
import zipfile

from pretf import workflow
from pretf.aws import get_session
from pretf.test import SimpleTest

session = get_session(profile_name="rbutcher", region_name="eu-west-1")
lambda_client = session.client("lambda")


class TestFilename(SimpleTest):
    def test_init_terraform(self):
        workflow.delete_files("**/*.json", "*.zip")
        workflow.create_files()
        self.init()

    def test_create_zip(self):
        with zipfile.ZipFile("test2.zip", "w") as zip_file:
            zip_file.write("src/lambda.py", "lambda.py")

    def test_deploy(self):
        self.apply()

    def test_invoke_lambda_functions(self):
        response = lambda_client.invoke(
            FunctionName="terraform-aws-lambda-builder-filename1"
        )
        payload = json.load(response["Payload"])
        assert payload == {"success": True}

        response = lambda_client.invoke(
            FunctionName="terraform-aws-lambda-builder-filename2"
        )
        payload = json.load(response["Payload"])
        assert payload == {"success": True}

    def test_change(self):

        with open("src/hello.json", "w") as open_file:
            json.dump({"hello": True}, open_file)

        self.apply()

        response = lambda_client.invoke(
            FunctionName="terraform-aws-lambda-builder-filename1"
        )
        payload = json.load(response["Payload"])
        assert payload == {"success": True, "hello": True}

    def test_destroy(self):
        self.destroy()
