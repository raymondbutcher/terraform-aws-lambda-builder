import json

from pretf import test
from pretf.aws import get_session

session = get_session(profile_name="rbutcher", region_name="eu-west-1")
lambda_client = session.client("lambda")


class TestS3(test.SimpleTest):
    def test_init_terraform(self):
        """
        Configure and initialize the backend.

        """

        self.pretf.init()

    def test_deploy_lambda_function(self):
        """
        Deploy the Lambda function.

        """

        self.pretf.apply()

    def test_invoke_lambda_function(self):
        """
        Invoke the Lambda function.

        """

        response = lambda_client.invoke(FunctionName="terraform-aws-lambda-builder-s3")
        payload = json.load(response["Payload"])
        assert payload == {"success": True}

    @test.always
    def test_destroy(self):
        """
        Clean up after the test.

        """

        self.pretf.destroy()
