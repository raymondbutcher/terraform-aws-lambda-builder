import json

from pretf import workflow
from pretf.aws import get_session
from pretf.test import SimpleTest

session = get_session(profile_name="rbutcher", region_name="eu-west-1")
lambda_client = session.client("lambda")


FUNCTION_NAME = "terraform-aws-lambda-builder-numpy"


class TestNumpy(SimpleTest):
    def test_init_terraform(self):
        """
        Configure and initialize the backend.

        """

        workflow.delete_files()
        workflow.create_files()

        self.init()

    def test_deploy_lambda_function(self):
        """
        Deploy the Lambda function.

        """

        outputs = self.apply()
        function_name = outputs["function_name"]
        assert function_name == FUNCTION_NAME

    def test_invoke_lambda_function(self):
        """
        Invoke the Lambda function to ensure numpy works.

        """

        response = lambda_client.invoke(FunctionName=FUNCTION_NAME)
        payload = json.load(response["Payload"])

        assert payload["success"]
