# Snapd REST API - OpenAPI Specification

This repository contains the official OpenAPI 3.x specification for the SnapD REST API. The goal of this project is to provide a modern, maintainable, and machine-readable definition of the API that serves as the single source of truth for development, documentation, and testing.

## Project Status

This project has completed its initial porting and tooling phases.
* ✅ **Core API Ported**: All primary v2 endpoints from the original documentation have been ported.
* ✅ **Developer Toolkit**: A powerful BASH script (`./controller.sh`) has been created to validate, test, and generate artifacts.
* ✅ **Continuous Integration**: A GitHub Actions workflow automatically validates the specification on every pull request to ensure quality and consistency.
* ⏳ **Next Step**: Planning is underway to upgrade the specification from OpenAPI v3.0.4 to v3.1.0.

---

## Developer Toolkit & Usage

This repository includes a BASH controller script to streamline development.

### 1. Installation

First, run the installer to ensure you have all the required dependencies (e.g., Node.js, Python, NPM/PIP packages).

./controller.sh --install

### 2. Available Commands

The controller script provides several utilities:

| Flag | Alias | Argument | Description |
| :--- | :--- | :--- | :--- |
| `-c` | `--csv` | (none) | Generates a `report.csv` file summarizing all defined endpoints and their HTTP methods. |
| `-d` | `--graph` | `[--dark]` | Generates a `dependency-graph.png` visual of how paths and components are connected. Use `--dark` for a dark-mode theme. |
| `-g` | `--generate` | `<lang>` | Generates a client SDK in the specified language (e.g., `python`, `go`, `typescript-fetch`). |
| `-h` | `--help` | (none) | Displays the help message with all available commands. |
| `-i` | `--install` | (none) | Installs all required local dependencies for the script. |
| `-m` | `--mock-server`| (none) | Launches a local mock API server using Prism based on the specification's examples. |
| `-p` | `--prompt` | (none) | Formats and copies the entire project's structure and file contents into a prompt suitable for an LLM. |
| `-s` | `--swagger` | (none) | Bundles the spec and generates a self-contained `swagger-ui.html` file for interactive documentation. |
| | `--sphinx` | `[dir]` | Converts the generated Swagger HTML into an embedding for a Sphinx documentation project. |
| `-v` | `--validate` | (none) | Validates the entire OpenAPI specification for syntax errors and inconsistencies. |


---

## Key Benefits of This Approach

This multi-file, component-based approach provides several key advantages over a single, large documentation file.

#### 1. Maintainability
Instead of searching through a 20,000-line file, a developer can immediately navigate to the file for the resource they need to modify (e.g., editing the `/v2/users` endpoint by opening `v2/paths/users.yaml`).

#### 2. Reusability (DRY Principle)
By defining common data objects like `Snap` or `StandardError` in the `components/` directory, we can reuse them across many different endpoints. This ensures consistency and means that an update to a a data model only needs to be made in **one single place**.

#### 3. Automation and Tooling Ecosystem
A valid OpenAPI specification is more than just documentation; it's a key that unlocks a vast ecosystem of development tools:

* **Interactive Documentation**: Tools like [Swagger UI](https://swagger.io/tools/swagger-ui/) and [Redoc](https://github.com/Redocly/redoc) can automatically generate beautiful, interactive API docs directly from this specification (`./controller.sh -s`).
* **Client SDK Generation**: Use tools like [OpenAPI Generator](https://openapi-generator.tech/) to automatically generate client libraries in dozens of languages (`./controller.sh -g python`).
* **Mock Servers**: Quickly spin up a mock API server that returns example data, allowing frontend and client developers to work in parallel with the backend team (`./controller.sh -m`).
* **Automated Testing**: The specification can be used to generate contract tests, ensuring the live API implementation never deviates from its definition.

---

## How to Contribute

1.  **Read CONTRIBUTING.md**: For detailed information on commiting and the optimal workflow.
2.  **Find the right file**:
    * To modify an endpoint (e.g., `POST /v2/snaps/{name}`), open the corresponding file: `v2/paths/snaps-name.yaml`.
    * To modify a data model (e.g., the `Snap` object), open the corresponding file: `v2/components/schemas/Snap.yaml`.
3.  **Make your changes**.
4.  **Use existing components**: Before creating a new schema, check `v2/components/schemas/` to see if a suitable one already exists. Always prefer using `$ref` to link to an existing component over redefining it.
5.  **Validate your changes locally**: Run `./controller.sh --validate` to ensure your changes are valid before committing.
6.  **Submit a Pull Request**: A CI workflow will automatically validate your changes again, ensuring the integrity of the `main` branch.

---

## Project Roadmap

* **Upgrade to OpenAPI 3.1.0**: Migrate the specification to the latest version to leverage modern JSON Schema support and other improvements.
* **Drive API Design**: The ultimate goal is for this OpenAPI specification to drive the SnapD API's design and development, using code generation and automated contract testing to ensure the implementation and documentation are always synchronized.