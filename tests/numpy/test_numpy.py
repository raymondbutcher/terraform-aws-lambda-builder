import json

from pretf import test
from pretf.aws import get_session

session = get_session(profile_name="rbutcher", region_name="eu-west-1")
lambda_client = session.client("lambda")


FUNCTION_NAME = "terraform-aws-lambda-builder-numpy"


class TestNumpy(test.SimpleTest):
    def test_init_terraform(self):
        """
        Configure and initialize the backend.

        """

        self.pretf.init()

    def test_deploy_lambda_function(self):
        """
        Deploy the Lambda function.

        """

        outputs = self.pretf.apply()
        function_name = outputs["function_name"]
        assert function_name == FUNCTION_NAME

    def test_invoke_lambda_function(self):
        """
        Invoke the Lambda function to ensure numpy works.
        (numpy was installed by pip in the build script)

        """

        response = lambda_client.invoke(FunctionName=FUNCTION_NAME)
        payload = json.load(response["Payload"])

        assert payload["success"]

    @test.always
    def test_destroy(self):
        """
        Clean up after the test.

        """

        self.pretf.destroy()
