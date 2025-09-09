# --- Variables ---
# Use the same public Docker image as the CI pipeline (no Dockerfile needed)
IMAGE_NAME = redocly/cli

# Source and target directories/files
SRC_DIR = template/
SRC = $(SRC_DIR)sample.yaml
BUILD_DIR = dist/
TARGET = $(BUILD_DIR)api-docs.html

# --- Main Targets ---
.PHONY: all lint build lint-local build-local

## all: Lints the specification and builds the documentation (default).
all: lint build

## lint: Lints the API specification using Redocly in Docker.
lint:
	@echo "--- Linting API specification ---"
	docker run --rm \
		-v "$(CURDIR)":/spec:z \
		-w /spec \
		$(IMAGE_NAME) lint $(SRC)

## build: Builds static HTML documentation using Redocly in Docker.
build:
	@echo "--- Building documentation ---"
	@mkdir -p $(BUILD_DIR)
	docker run --rm \
		-v "$(CURDIR)":/spec:z \
		-w /spec \
		$(IMAGE_NAME) build-docs $(SRC) -o $(TARGET)

## lint-local: Lints using a Redocly CLI installed on your machine.
lint-local:
	redocly lint $(SRC)

## build-local: Builds using a Redocly CLI installed on your machine.
build-local:
	@mkdir -p $(BUILD_DIR)
	redocly build-docs $(SRC) -o $(TARGET)

# --- Helper Targets ---
.PHONY: clean

## clean: Removes the build output directory.
clean:
	@echo "--- Removing build artifacts ---"
	rm -rf $(BUILD_DIR)