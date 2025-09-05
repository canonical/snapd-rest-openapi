# --- Variables ---
IMAGE_NAME = swagger-builder-env
TARGET_DIR = output/
TARGET = $(TARGET_DIR)index.html
SRC_DIR = template/
SRC = $(SRC_DIR)sample.yaml

# --- Main Targets ---
.PHONY: all build build-image build-local
all: build

## build: Builds the static HTML using our custom Docker environment.
build: build-image
	docker run --rm \
		--user "$(id -u):$(id -g)" \
		-v "$(CURDIR)":/docs:z \
		-w "/docs" \
		$(IMAGE_NAME) \
		swagger-ui-cli build $(SRC) -o $(TARGET_DIR)

## build-image: Builds the Docker image that contains our build tools.
build-image:
	docker build -t $(IMAGE_NAME) .

## build-local: Builds using a swagger-ui-cli installed on your machine.
build-local:
	swagger-ui-cli build $(SRC) -o $(TARGET_DIR)

# --- Helper Targets ---
.PHONY: clean

## clean: Removes the build output directory and any created cache.
clean:
	@echo "--- Removing build artifacts and cache ---"
	rm -rf $(TARGET_DIR) .npm

