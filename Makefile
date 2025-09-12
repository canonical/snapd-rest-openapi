# SPDX-License-Identifier: GPL-3.0
# SPDX-FileCopyrightText: Canonical Ltd

# Makefile to replicate the Redocly GitHub CI workflow locally using Docker.
#
# This requires Docker to be installed and the daemon running.

# Define the Redocly CLI Docker image and the command prefix.
# Mount the current directory to /spec inside the container, just like the CI.
REDOCLY_CMD = docker run --rm -v "$(CURDIR):/spec" redocly/cli

# Default target: runs both linting and building, mimicking the full CI job.
all: lint build

# Lint the OpenAPI specification.
lint:
	@echo "--- Linting OpenAPI specification... ---"
	$(REDOCLY_CMD) lint ./openapi.yaml

# Build the static HTML documentation.
build:
	@echo "--- Building documentation... ---"
	$(REDOCLY_CMD) build-docs ./openapi.yaml
	@echo "--- Documentation built successfully: redoc-static.html ---"

# Clean up generated files.
clean:
	@echo "--- Removing generated documentation... ---"
	@rm -f redoc-static.html

# Phony targets are not actual files.
.PHONY: all lint build clean
