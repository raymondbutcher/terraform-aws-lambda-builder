import json

from pretf import workflow
from pretf.aws import get_session
from pretf.test import SimpleTest

session = get_session(profile_name="rbutcher", region_name="eu-west-1")
lambda_client = session.client("lambda")


class TestS3(SimpleTest):
    def test_init_terraform(self):
        workflow.delete_files("*.json", "*.zip")
        workflow.create_files()
        self.init()

    def test_deploy(self):
        self.apply()

    def test_invoke_lambda_functions(self):
        response = lambda_client.invoke(FunctionName="terraform-aws-lambda-builder-s3")
        payload = json.load(response["Payload"])
        assert payload == {"success": True}

    def test_destroy(self):
        self.destroy()
