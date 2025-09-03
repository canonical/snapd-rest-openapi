# --- Variables ---
TARGET_DIR = output/
TARGET = $(TARGET_DIR)index.html
SRC_DIR = template/
SRC = $(SRC_DIR)sample.yaml

# --- Main Targets ---
.PHONY: all build build-local test
all: build

## build: Builds the static HTML inside a Docker container.
build:
	@echo "--- Building static HTML with Docker ---"
	docker run --rm \
		--user "$(id -u):$(id -g)" \
		-e HOME=/docs \
		-v "$(CURDIR)":"/docs" \
		-w "/docs" \
		node:20-alpine \
		npx swagger-ui-cli build $(SRC) -o $(TARGET_DIR)

	chmod -R u+rwX,go+rX $(TARGET_DIR)

## build-local: Builds using a swagger-ui-cli installed on your machine.
build-local:
	@echo "--- Building static HTML locally ---"
	swagger-ui-cli build $(SRC) -o $(TARGET_DIR)

## test: Checks if the build artifact was created successfully.
test:
	@echo "--- Testing for existence of build output ---"
	@if [ -f "$(TARGET)" ]; then \
		echo "Test Passed: $(TARGET) found."; \
	else \
		echo "Test Failed: $(TARGET) not found." >&2; \
		exit 1; \
	fi

# --- Helper Targets ---
.PHONY: serve clean

## serve: Serves the static files from the './output' directory.
serve: build
	@echo "--- Serving static files on http://localhost:8080 ---"
	docker run --rm -it \
		-p 8080:8080 \
		-v "$(CURDIR)/$(TARGET_DIR)":/usr/share/nginx/html \
		nginx:alpine

## clean: Removes the build output directory.
clean:
	@echo "--- Removing build artifacts from $(TARGET_DIR) ---"
	rm -rf $(TARGET_DIR)