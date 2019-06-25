import json
import zipfile

from pretf import test, workflow
from pretf.aws import get_session

session = get_session(profile_name="rbutcher", region_name="eu-west-1")
lambda_client = session.client("lambda")


class TestFilename(test.SimpleTest):
    def test_init_terraform(self):
        """
        Configure and initialize the backend.

        """

        workflow.delete_files("**/*.json", "*.zip")
        self.pretf.init()

    def test_deploy_lambda_function(self):
        """
        Deploy the Lambda function.

        """

        # Create a zip file to use.
        with zipfile.ZipFile("test2.zip", "w") as zip_file:
            zip_file.write("src/lambda.py", "lambda.py")

        self.pretf.apply()

    def test_invoke_lambda_functions(self):
        """
        Invoke the Lambda functions.

        """

        response = lambda_client.invoke(
            FunctionName="terraform-aws-lambda-builder-filename1"
        )
        payload = json.load(response["Payload"])
        assert payload == {"success": True}
        assert "hello" not in payload

        response = lambda_client.invoke(
            FunctionName="terraform-aws-lambda-builder-filename2"
        )
        payload = json.load(response["Payload"])
        assert payload == {"success": True}
        assert "hello" not in payload

    def test_change(self):
        """
        Change the contents of source_dir so the module
        updates the function. Deploy the updated function
        and invoke it to check for the changed payload.

        """

        with open("src/hello.json", "w") as open_file:
            json.dump({"hello": True}, open_file)

        self.pretf.apply()

        response = lambda_client.invoke(
            FunctionName="terraform-aws-lambda-builder-filename1"
        )
        payload = json.load(response["Payload"])
        assert payload == {"success": True, "hello": True}

    @test.always
    def test_destroy(self):
        """
        Clean up after the test.

        """

        self.pretf.destroy()
