PRECOMMIT_VERSION="2.21.0"
SHELL := /bin/bash
NODE_PATH = $(which node)
PATH := $(NODE_PATH):$(shell echo $$PATH)

all: tflint pre-commit commitlint husky

tflint:
	curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

pre-commit:
	wget -O pre-commit.pyz https://github.com/pre-commit/pre-commit/releases/download/v${PRECOMMIT_VERSION}/pre-commit-${PRECOMMIT_VERSION}.pyz
	python3 pre-commit.pyz uninstall
	python3 pre-commit.pyz install -f --install-hooks
	rm pre-commit.pyz

commitlint:
	cd ../ && npm install --save-dev @commitlint/{cli,config-conventional} \
	&& echo "module.exports = { extends: ['@commitlint/config-conventional'] };" > commitlint.config.js

husky:
	cd ../ && npm install husky --save-dev \
	&& npx husky install \
	&& if [ ! -f .husky/commit-msg ]; then npx husky add .husky/commit-msg  "npx --no -- commitlint --edit ${1}"; fi
