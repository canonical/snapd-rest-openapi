# SPDX-FileCopyrightText: 2025 Canonical Ltd
# SPDX-License-Identifier: GPL-3.0-only

# --- Docker Command Definitions ---
# Redocly CLI: Mounts current directory to /spec for API linting/building.
REDOCLY_CMD = docker run --rm -v "$(CURDIR):/spec" redocly/cli
# REUSE tool: Mounts to /spec and sets it as the working directory for compliance checks.
REUSE_CMD = docker run --rm -v "$(CURDIR):/spec" -w /spec fsfe/reuse

# --- Main Targets ---
# Default target: runs all linting and the documentation build.
all: lint build

# Run all linting checks. This target calls the specific linters.
lint: lint-api lint-reuse

# Build the static HTML documentation.
build:
	@echo "--- Building documentation... ---"
	$(REDOCLY_CMD) build-docs ./openapi.yaml
	@echo "--- Documentation built successfully: redoc-static.html ---"

# Clean up generated files.
clean:
	@echo "--- Removing generated documentation... ---"
	@rm -f redoc-static.html


# --- Specific Linting Targets ---
# Lint the OpenAPI specification with Redocly.
lint-api:
	@echo "--- Linting OpenAPI specification (Redocly)... ---"
	$(REDOCLY_CMD) lint ./openapi.yaml

# Check for REUSE licensing and copyright compliance.
lint-reuse:
	@echo "--- Checking for REUSE compliance... ---"
	$(REUSE_CMD) lint


# Phony targets are not actual files.
.PHONY: all lint lint-api lint-reuse build clean
