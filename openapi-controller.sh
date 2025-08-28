#!/bin/bash

# ==============================================================================
# openapi-controller.sh
#
# A helper script for managing the SnapD OpenAPI specification project.
# Provides tools for installing dependencies, validating the spec, generating
# SDKs, and creating documentation.
# ==============================================================================

set -e # Exit immediately if a command exits with a non-zero status.


# --- Configuration ---
VENV_DIR=".venv"
SPEC_FILE="openapi.yaml"
BUNDLED_SPEC_FILE="openapi.bundled.yaml" # Temporary file for the bundled spec
PYTHON_CMD="python3"
PROMPT_DIR="prompts"
SDK_DIR="generated-sdks"
SWAGGER_STANDALONE_DIR="docs/swagger/" # Default for standalone swagger-ui
SPHINX_DEFAULT_DIR="docs/_static/api" # Default for Sphinx integration
NODE_VERSION="22"

# --- Helper Functions ---

# Function to print colored messages
log() {
    local level=$1
    local msg=$2
    local color_info="\033[0;34m"
    local color_success="\033[0;32m"
    local color_warn="\033[0;33m"
    local color_error="\033[0;31m"
    local color_reset="\033[0m"

    case "$level" in
        INFO)    echo -e "${color_info}[INFO]${color_reset} $msg" ;;
        SUCCESS) echo -e "${color_success}[SUCCESS]${color_reset} $msg" ;;
        WARN)    echo -e "${color_warn}[WARN]${color_reset} $msg" ;;
        ERROR)   echo -e "${color_error}[ERROR]${color_reset} $msg" ;;
        *)       echo "$msg" ;;
    esac
}

# Function to display help information
show_help() {
    echo "SnapD OpenAPI Management Script"
    echo "-------------------------------"
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  -c, --csv             Generate a CSV file mapping endpoints to their available HTTP methods."
    echo "  -d, --graph [--dark]  Generate SVG dependency graphs. Use --dark for a dark theme."
    echo "  -g, --generate <lang> Generate a client SDK for the specified language."
    echo "  -i, --install         Set up the Python virtual environment, Node.js and install all required tools."
    echo "  -h, --help            Display this help message."
    echo "  -m, --mock-server     Start a local mock server based on the OpenAPI specification."
    echo "  -p, --prompt          Generate a single project context file for use with an LLM."
    echo "  -s, --swagger         Generate a standalone HTML file ('$SWAGGER_STANDALONE_DIR/index.html') for API documentation."
    echo "      --sphinx [dir]    Generate documentation for Sphinx integration. Defaults to '$SPHINX_DEFAULT_DIR'."
    echo "  -v, --validate        Validate the main '$SPEC_FILE' specification using Redocly."
    echo
}

# --- Core Functions ---

# Function to install dependencies
install_dependencies() {
    log "INFO" "Starting dependency installation..."

    # --- System Dependencies (Debian/Ubuntu-based) ---
    log "INFO" "Checking for system dependencies (python, venv, tree, curl, graphviz)..."
    local missing_pkgs=""
    if ! command -v $PYTHON_CMD > /dev/null; then missing_pkgs+="python3 "; fi
    if ! dpkg -s python3-venv > /dev/null 2>&1; then missing_pkgs+="python3-venv "; fi
    if ! command -v tree > /dev/null; then missing_pkgs+="tree "; fi
    if ! command -v curl > /dev/null; then missing_pkgs+="curl "; fi
    if ! command -v dot > /dev/null; then missing_pkgs+="graphviz "; fi

    if [ -n "$missing_pkgs" ]; then
        log "INFO" "The following packages are missing: $missing_pkgs"
        log "WARN" "This may require sudo privileges to install."
        sudo apt-get update && sudo apt-get install -y $missing_pkgs
    else
        log "SUCCESS" "All required system dependencies are already installed."
    fi

    # --- Node.js Installation (via nvm) ---
    log "INFO" "Setting up Node.js environment using nvm..."
    export NVM_DIR="$HOME/.nvm"
    
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        log "INFO" "nvm not found. Installing nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
    
    . "$NVM_DIR/nvm.sh"
    
    log "INFO" "Installing and using Node.js v$NODE_VERSION..."
    nvm install "$NODE_VERSION" > /dev/null
    nvm use "$NODE_VERSION" > /dev/null
    
    log "SUCCESS" "Node.js setup complete. Using Node version: $(node -v)"

    # --- Install Node.js-based CLI tools ---
    log "INFO" "Installing global CLI tools (Redocly, Swagger UI, OpenAPI Generator, Prism)..."
    npm install -g --silent @redocly/cli swagger-ui-cli @openapitools/openapi-generator-cli @stoplight/prism-cli

    # --- Python Virtual Environment ---
    if [ ! -f "$VENV_DIR/bin/pip" ]; then
        if [ -d "$VENV_DIR" ]; then
            log "WARN" "Incomplete virtual environment detected. Recreating..."
            rm -rf "$VENV_DIR"
        fi
        log "INFO" "Creating Python virtual environment in '$VENV_DIR'..."
        $PYTHON_CMD -m venv "$VENV_DIR"
        log "SUCCESS" "Virtual environment created."
    else
        log "INFO" "Virtual environment '$VENV_DIR' already exists and appears valid."
    fi
    
    log "INFO" "Installing Python dependencies (PyYAML)..."
    "$VENV_DIR/bin/pip" install -q PyYAML
    
    log "SUCCESS" "Installation and setup complete."
}

# Function to validate the OpenAPI specification
validate_spec() {
    log "INFO" "Validating OpenAPI specification using Redocly CLI..."
    if ! command -v redocly > /dev/null; then
        log "ERROR" "Redocly CLI not found. Please run './openapi-controller.sh --install' first."
        exit 1
    fi
    
    if redocly lint "$SPEC_FILE"; then
        log "SUCCESS" "Validation successful! The OpenAPI specification is valid."
    else
        log "ERROR" "Validation failed. Please check the errors above."
        exit 1
    fi
}

# Function to generate a CSV report of endpoints and methods
generate_csv_report() {
    log "INFO" "Generating endpoint methods CSV report..."
    
    if [ ! -f "./scripts/report_generator.py" ]; then
        log "ERROR" "The 'scripts/report_generator.py' script was not found in this directory."
        exit 1
    fi
    
    log "INFO" "Executing Python script to parse spec..."
    "$VENV_DIR/bin/python3" ./scripts/report_generator.py
}

# Function to generate a prompt file for LLMs
generate_prompt_file() {
    log "INFO" "Generating LLM prompt file..."
    mkdir -p "$PROMPT_DIR"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local prompt_file="$PROMPT_DIR/prompt_${timestamp}.txt"

    local BLACKLIST_PATHS=( ".venv" "$PROMPT_DIR" "$SDK_DIR" ".git" "node_modules" "swagger-dist" )
    local BLACKLIST_NAMES=( "$BUNDLED_SPEC_FILE" "swagger.html" "*.svg" "*.dot" "*.ods" )

    local all_blacklist=("${BLACKLIST_PATHS[@]}" "${BLACKLIST_NAMES[@]}")
    local tree_ignore_pattern=$(IFS='|'; echo "${all_blacklist[*]}")

    log "INFO" "Writing project structure and file contents to '$prompt_file'..."

    {
        echo "Project Directory Structure:"
        echo "============================"
        tree -a -I "$tree_ignore_pattern"
        echo -e "\n\n"
        echo "File Contents:"
        echo "=============="
    } > "$prompt_file"

    local find_exclude_args=()
    for path in "${BLACKLIST_PATHS[@]}"; do
        find_exclude_args+=(-not -path "./$path/*")
    done
    for name in "${BLACKLIST_NAMES[@]}"; do
        find_exclude_args+=(-not -name "$name")
    done

    find . -type f "${find_exclude_args[@]}" | while read -r file; do
        {
            echo "----------------------------------------"
            echo "### File: ${file}"
            echo "----------------------------------------"
            cat "${file}"
            echo -e "\n\n"
        } >> "$prompt_file"
    done

    log "SUCCESS" "Prompt file created at '$prompt_file'."
    log "WARN" "LLMs should not be regarded as a factual source of information, verify the output makes sense."
}

# Function to generate an SDK
generate_sdk() {
    local language=$1
    if [ -z "$language" ]; then
        log "ERROR" "No language specified for SDK generation."
        log "INFO" "Usage: $0 --generate <language>"
        exit 1
    fi

    log "INFO" "Sourcing nvm to ensure commands are available..."
    export NVM_DIR="$HOME/.nvm"
    . "$NVM_DIR/nvm.sh"

    log "INFO" "Generating '$language' SDK using 'openapi-generator-cli'..."
    if ! command -v openapi-generator-cli > /dev/null; then
        log "ERROR" "'openapi-generator-cli' not found. Run './openapi-controller.sh --install' first."
        exit 1
    fi

    local output_path="$SDK_DIR/$language"
    mkdir -p "$output_path"

    log "INFO" "Output directory: '$output_path'"
    
    openapi-generator-cli generate -i "$SPEC_FILE" -g "$language" -o "$output_path"

    log "SUCCESS" "'$language' SDK generated successfully in '$output_path'."
}

# Function to generate Swagger UI documentation
generate_swagger_docs() {
    local output_dir=$1
    log "INFO" "Generating Swagger UI documentation in '$output_dir'..."
    mkdir -p "$output_dir"

    log "INFO" "Step 1: Bundling spec with Redocly CLI to resolve all references..."
    if ! command -v redocly > /dev/null; then
        log "ERROR" "Redocly CLI not found. Please run './openapi-controller.sh --install' first."
        exit 1
    fi
    
    trap 'log "INFO" "Cleaning up temporary files..."; rm -f "$BUNDLED_SPEC_FILE" visuals/*.dot' EXIT
    
    if ! redocly bundle "$SPEC_FILE" -o "$BUNDLED_SPEC_FILE"; then
        log "ERROR" "Redocly failed to bundle the specification."
        exit 1
    fi
    log "SUCCESS" "Specification bundled successfully into '$BUNDLED_SPEC_FILE'."

    log "INFO" "Step 2: Building HTML from the bundled spec using Swagger UI CLI..."
    if ! command -v swagger-ui-cli > /dev/null; then
        log "ERROR" "Swagger UI CLI not found. Please run './openapi-controller.sh --install' first."
        exit 1
    fi

    if swagger-ui-cli build "$BUNDLED_SPEC_FILE" -o "$output_dir"; then
        log "SUCCESS" "Swagger UI documentation has been generated in '$output_dir'."
    else
        log "ERROR" "Swagger UI CLI failed to build the HTML file."
        exit 1
    fi
}

# Function to generate dependency graphs
generate_dependency_graph() {
    local dark_mode_arg=""
    if [ "$1" == "--dark" ]; then
        dark_mode_arg="--dark"
        log "INFO" "Dark mode enabled for graphs."
    fi

    log "INFO" "Generating separate dependency graphs..."
    
    if ! command -v redocly > /dev/null || ! command -v dot > /dev/null || [ ! -f "./scripts/graph_generator.py" ]; then
        log "ERROR" "Missing dependencies. Redocly, graphviz, or graph_generator.py not found."
        log "INFO" "Please run './openapi-controller.sh --install' and ensure 'scripts/graph_generator.py' exists."
        exit 1
    fi

    log "INFO" "Bundling spec with Redocly CLI..."
    trap 'log "INFO" "Cleaning up temporary files..."; rm -f "$BUNDLED_SPEC_FILE" visuals/*.dot' EXIT
    if ! redocly bundle "$SPEC_FILE" -o "$BUNDLED_SPEC_FILE"; then
        log "ERROR" "Redocly failed to bundle the specification."
        exit 1
    fi
    log "SUCCESS" "Specification bundled successfully."

    log "INFO" "Generating graph data with graph_generator.py..."
    "$VENV_DIR/bin/python3" ./scripts/graph_generator.py "$BUNDLED_SPEC_FILE" "$dark_mode_arg"
    log "SUCCESS" "Graph data generation complete."

    log "INFO" "Rendering SVG images with graphviz (dot)..."
    local generated_files=()
    for dot_file in visuals/*.dot; do
        if [ -f "$dot_file" ]; then
            local svg_file="${dot_file%.dot}.svg"
            dot -Tsvg "$dot_file" -o "$svg_file"
            log "SUCCESS" "Rendered graph: $svg_file"
            generated_files+=("$svg_file")
        fi
    done
    
    if [ ${#generated_files[@]} -eq 0 ]; then
        log "WARN" "No dependency graphs were generated. This may be expected if there are no relationships to show."
    else
        log "INFO" "All dependency graphs have been generated."
    fi
}

# NEW: Function to start a mock server
start_mock_server() {
    log "INFO" "Starting mock server with Prism..."

    if ! command -v redocly > /dev/null || ! command -v prism > /dev/null; then
        log "ERROR" "Missing dependencies. Redocly or Prism CLI not found."
        log "INFO" "Please run './openapi-controller.sh --install' first."
        exit 1
    fi

    log "INFO" "Bundling spec with Redocly CLI..."
    trap 'log "INFO" "Cleaning up temporary files..."; rm -f "$BUNDLED_SPEC_FILE"' EXIT
    if ! redocly bundle "$SPEC_FILE" -o "$BUNDLED_SPEC_FILE"; then
        log "ERROR" "Redocly failed to bundle the specification."
        exit 1
    fi
    log "SUCCESS" "Specification bundled successfully into '$BUNDLED_SPEC_FILE'."

    log "INFO" "Starting Prism mock server. Press Ctrl+C to stop."
    log "INFO" "API will be available at http://127.0.0.1:4010"
    prism mock "$BUNDLED_SPEC_FILE"
}


# --- Main Execution Logic ---
if [ $# -eq 0 ]; then
    log "ERROR" "No arguments provided."
    show_help
    exit 1
fi

case "$1" in
    -c|--csv)
        generate_csv_report
        ;;
    -i|--install)
        install_dependencies
        ;;
    -v|--validate)
        validate_spec
        ;;
    -p|--prompt)
        generate_prompt_file
        ;;
    -g|--generate)
        generate_sdk "$2"
        ;;
    -s|--swagger)
        generate_swagger_docs "$SWAGGER_STANDALONE_DIR"
        ;;
    -d|--graph)
        # Pass the next argument ($2) to the function
        generate_dependency_graph "$2"
        ;;
    -m|--mock-server)
        start_mock_server
        ;;
    --sphinx)
        if [ -n "$2" ] && [[ $2 != -* ]]; then
            sphinx_dir="$2"
        else
            sphinx_dir="$SPHINX_DEFAULT_DIR"
        fi
        generate_swagger_docs "$sphinx_dir"
        ;;
    -h|--help)
        show_help
        ;;
    *)
        log "ERROR" "Invalid option: $1"
        show_help
        exit 1
        ;;
esac

exit 0
