import json

import pytest
from pretf import test
from pretf.aws import get_session

session = get_session(profile_name="rbutcher", region_name="eu-west-1")
lambda_client = session.client("lambda")


FUNCTION_NAMES = [
    "terraform-aws-lambda-builder-python-36",
    "terraform-aws-lambda-builder-python-37",
    "terraform-aws-lambda-builder-python-38",
    "terraform-aws-lambda-builder-python-39",
]


class TestPython(test.SimpleTest):
    def test_init_terraform(self):
        """
        Configure and initialize the backend.

        """

        self.pretf.init()

    def test_deploy_lambda_functions(self):
        """
        Deploy the Lambda function.

        """

        outputs = self.pretf.apply()
        function_names = outputs["function_names"]
        assert function_names == FUNCTION_NAMES

    @pytest.mark.parametrize("function_name", FUNCTION_NAMES)
    def test_invoke_lambda_function(self, function_name):
        """
        Invoke the Lambda function to ensure it works.
        The function uses numpy which should have been
        installed by build script.
        
        """

        response = lambda_client.invoke(FunctionName=function_name)
        payload = json.load(response["Payload"])

        assert payload["success"]

    @test.always
    def test_destroy(self):
        """
        Clean up after the test.

        """

        self.pretf.destroy()
