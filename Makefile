.PHONY: all
all:
	isort --recursive *.py lambda_builders tests
	black *.py lambda_builders tests
	flake8 --ignore E501 *.py lambda_builders tests
	terraform fmt -recursive

.PHONY: clean
clean:
	find tests -maxdepth 3 -name '*.json' -delete
	find zip_files -name '*.zip' -delete

.PHONY: test tests
test tests:
	pytest -v -n auto --dist=loadfile tests
