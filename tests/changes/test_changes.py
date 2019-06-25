import json

from pretf import test
from pretf.aws import get_session

session = get_session(profile_name="rbutcher", region_name="eu-west-1")
lambda_client = session.client("lambda")
s3_client = session.client("s3")


# TODO: check s3 bucket to ensure change of files and cleanup of old ones, and empty after destroy


class TestChanges(test.SimpleTest):
    def test_init_terraform(self):
        """
        Configure and initialize the backend.

        """

        self.pretf.init()

    def test_deploy_lambda_function(self):
        """
        Write "1" into a file in the source directory,
        run "terraform apply" to deploy the function,
        then invoke the function and check it returned "1".

        """

        self.set_source_version(1)
        self.apply_terraform_and_check_version(1)

    def test_update_lambda_function(self):
        """
        Write "2" into a file in the source directory,
        run "terraform apply" to update the function,
        then invoke the function and check it returned "2".

        """

        self.set_source_version(2)
        self.apply_terraform_and_check_version(2)

    def apply_terraform_and_check_version(self, version):
        # Run terraform apply and get the functions from the outputs.
        outputs = self.pretf.apply()
        function_names = outputs["function_names"]
        assert len(function_names) == 2

        # Check each function.
        for function_name in function_names:

            # Invoke the function and parse the result.
            response = lambda_client.invoke(FunctionName=function_name)
            payload = json.load(response["Payload"])

            # Check that the version matches what was written to version.json.
            assert payload["version"] == version

            # Check that the list of files in the package was altered by build.sh
            # which renames version.json to result.json.
            assert payload["files"] == ["build.sh", "lambda.py", "result.json"]

    def set_source_version(self, version):
        with open("src/version.json", "w") as open_file:
            json.dump({"version": version}, open_file)

    @test.always
    def test_destroy(self):
        """
        Clean up after the test.

        """

        self.pretf.destroy()
