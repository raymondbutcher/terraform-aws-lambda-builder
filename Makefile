.PHONY: all
all:
	isort --recursive *.py builders tests
	black *.py builders tests
	flake8 --ignore E501 *.py builders tests
	terraform fmt -recursive

.PHONY: clean
clean:
	find tests -maxdepth 3 -name '*.json' -delete
	find zip_files -name '*.zip' -delete
