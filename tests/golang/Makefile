# Create, test, and destroy the Lambda function.
.PHONY: test
test:
	pytest -v

# Test the deployed Lambda function by invoking it.
# This is useful if you want to test the function,
# but not create and destroy it with Terraform too.
.PHONY: invoke
invoke:
	pytest -v test_golang.py::TestGolang::test_invoke_lambda_function

# Builds the function locally in Docker, not exactly like CodeBuild,
# just enough to check if the Go code is right.
.PHONY: local
local:
	docker run -v $(PWD)/src:/tmp/src golang:1.14 sh -c " \
		cd /tmp/src && \
		go fmt && \
		cp -r . /go/src/lambda && \
		cd /go/src/lambda && \
		go get -d -v ./... && \
		go test && \
		go build -o main main.go \
	"
