import json

import pytest
from pretf import test
from pretf.aws import get_session

session = get_session(profile_name="rbutcher", region_name="eu-west-1")
lambda_client = session.client("lambda")


FUNCTION_NAMES = [
    "terraform-aws-lambda-builder-nodejs-10",
    "terraform-aws-lambda-builder-nodejs-12",
]


class TestNodejs(test.SimpleTest):
    def test_init_terraform(self):
        """
        Configure and initialize the backend.

        """

        self.pretf.init()

    def test_deploy_lambda_functions(self):
        """
        Deploy the Lambda functions.

        """

        outputs = self.pretf.apply()
        function_names = outputs["function_names"]
        assert function_names == FUNCTION_NAMES

    @pytest.mark.parametrize("function_name", FUNCTION_NAMES)
    def test_invoke_lambda_function(self, function_name):
        """
        Invoke the Lambda function to ensure jsonwebtoken works.
        (jsonwebtoken was installed by npm in the build script)

        """

        response = lambda_client.invoke(FunctionName=function_name)
        payload = json.load(response["Payload"])

        assert payload["success"]
        assert "token" in payload

    @test.always
    def test_destroy(self):
        """
        Clean up after the test.

        """

        self.pretf.destroy()
