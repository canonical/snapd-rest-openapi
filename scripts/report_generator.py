import csv
import logging
import os
import sys
from pathlib import Path

# Set up basic logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Try to import PyYAML and provide a helpful error message if it's missing.
try:
    import yaml
except ImportError:
    logging.error("The 'PyYAML' package is required. Please run the install command from the controller script:")
    logging.error("./openapi-controller.sh --install")
    sys.exit(1)

# --- Configuration ---
ROOT_SPEC_FILE = "openapi.yaml"
OUTPUT_CSV_FILE = "endpoint_methods.csv"
VALID_METHODS = {"GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD", "TRACE"}


def main():
    """Parses the OpenAPI spec and generates a CSV report."""
    logging.info("Starting OpenAPI parser...")
    
    # Ensure the root spec file exists
    if not os.path.exists(ROOT_SPEC_FILE):
        logging.error(f"Root spec file '{ROOT_SPEC_FILE}' not found.")
        sys.exit(1)

    # Load the main openapi.yaml file
    try:
        with open(ROOT_SPEC_FILE, 'r') as f:
            spec = yaml.safe_load(f)
    except Exception as e:
        logging.error(f"Failed to read or parse '{ROOT_SPEC_FILE}': {e}")
        sys.exit(1)

    endpoint_data = {}

    # Process each path reference in the main spec file
    for path, path_ref_obj in spec.get("paths", {}).items():
        if '$ref' not in path_ref_obj:
            continue
        
        ref_path = Path(path_ref_obj['$ref'])
        
        try:
            with open(ref_path, 'r') as f:
                path_methods_data = yaml.safe_load(f)
        except Exception as e:
            logging.warning(f"Could not read or parse path file '{ref_path}': {e}")
            continue

        methods = [
            method.upper() for method in path_methods_data.keys() 
            if method.upper() in VALID_METHODS
        ]
        methods.sort()  # Sort alphabetically for consistent output
        endpoint_data[path] = methods

    # Write the collected data to a CSV file
    try:
        with open(OUTPUT_CSV_FILE, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            
            # Write header
            writer.writerow(["Endpoint", "Methods"])
            
            # Write data rows, sorted by endpoint path
            for path in sorted(endpoint_data.keys()):
                methods_str = ", ".join(endpoint_data[path])
                writer.writerow([path, methods_str])
    except Exception as e:
        logging.error(f"Failed to write to CSV file '{OUTPUT_CSV_FILE}': {e}")
        sys.exit(1)

    logging.info(f"Successfully generated CSV report: {OUTPUT_CSV_FILE}")


if __name__ == "__main__":
    main()