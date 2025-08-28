# SnapD API OpenAPI Porting Checklist

This document tracks the porting progress of the SnapD REST API from the original forum documentation to the OpenAPI 3.0.4 standard.

---

## Phase 1: Foundational Work (COMPLETE)

This phase involves setting up the project structure and defining the core, reusable data models.

- [x] **Project Scoping**: Analyzed the original HTML documentation to identify all API resources and data structures.
- [x] **Directory Structure**: Defined a logical, multi-file directory structure to separate paths and reusable components.
- [x] **Core Response Extraction**: Standardized responses provided by the server as a response.
    - [x] `v2/components/responses/Accepted.yaml`
    - [x] `v2/components/responses/BadRequest.yaml`
    - [x] `v2/components/responses/NotFound.yaml`
- [x] **Core Schema Extraction**: Identified and created the initial set of common, reusable schemas to ensure consistency and reduce duplication.
    - [x] `v2/components/schemas/App.yaml`
    - [x] `v2/components/schemas/AsyncOperation.yaml`
    - [x] `v2/components/schemas/Change.yaml`
    - [x] `v2/components/schemas/Connection.yaml`
    - [x] `v2/components/schemas/ConnectionEndpoint.yaml`
    - [x] `v2/components/schemas/ConnectionStatus.yaml`
    - [x] `v2/components/schemas/InstalledSnap.yaml`
    - [x] `v2/components/schemas/MediaItem.yaml`
    - [x] `v2/components/schemas/Notice.yaml`
    - [x] `v2/components/schemas/Publisher.yaml`
    - [x] `v2/components/schemas/QuotaGroup.yaml`
    - [x] `v2/components/schemas/Snap.yaml`
    - [x] `v2/components/schemas/Snapshot.yaml`
    - [x] `v2/components/schemas/SnapshotSet.yaml`
    - [x] `v2/components/schemas/StandardError.yaml`
    - [x] `v2/components/schemas/SystemInfo.yaml`
    - [x] `v2/components/schemas/Task.yaml`
    - [x] `v2/components/schemas/User.yaml`

---

## Phase 2: Endpoint Porting (COMPLETE)

This phase involves creating a YAML file for each API resource. Each file must define the endpoint's operations (GET, POST, etc.) and reference the reusable components from Phase 1 where applicable.

- [x] **Port `/v2/aliases`**: Create `v2/paths/aliases.yaml`.
- [x] **Port `/v2/apps`**: Create `v2/paths/apps.yaml`.
- [x] **Port `/v2/assertions`**: Create `v2/paths/assertions.yaml`.
- [x] **Port `/v2/assertions/{assertionType}`**: Create `v2/paths/assertions-type.yaml`.
- [x] **Port `/v2/changes`**: Create `v2/paths/changes.yaml`.
- [x] **Port `/v2/changes/{id}`**: Create `v2/paths/changes-id.yaml`.
- [x] **Port `/v2/cohorts`**: Create `v2/paths/cohorts.yaml`.
- [x] **Port `/v2/confdb`**: Create `v2/paths/confdb.yaml`.
- [x] **Port `/v2/connections`**: Create `v2/paths/connections.yaml`.
- [x] **Port `/v2/find`**: Create `v2/paths/find.yaml`.
- [x] **Port `/v2/icons`**: Create `v2/paths/icons.yaml`.
- [x] **Port `/v2/icons/{name}/icon`**: Create `v2/paths/icons-name.yaml`.
- [x] **Port `/v2/interfaces`**: Create `v2/paths/interfaces.yaml`.
- [x] **Port `/v2/login`**: Create `v2/paths/login.yaml`.
- [x] **Port `/v2/logout`**: Create `v2/paths/logout.yaml`.
- [x] **Port `/v2/logs`**: Create `v2/paths/logs.yaml`.
- [x] **Port `/v2/model`**: Create `v2/paths/model.yaml`.
- [x] **Port `/v2/model/serial`**: Create `v2/paths/model-serial.yaml`.
- [x] **Port `/v2/notices`**: Create `v2/paths/notices.yaml`.
- [x] **Port `/v2/quotas`**: Create `v2/paths/quotas.yaml`.
- [x] **Port `/v2/quotas/{group-name}`**: Create `v2/paths/quotas-name.yaml`.
- [x] **Port `/v2/sections`**: Create `v2/paths/sections.yaml`.
- [x] **Port `/v2/snapctl`**: Create `v2/paths/snapctl.yaml`.
- [x] **Port `/v2/snaps`**: Create `v2/paths/snaps.yaml`.
- [x] **Port `/v2/snaps/{name}`**: Create `v2/paths/snaps-name.yaml`.
- [x] **Port `/v2/snapshots`**: Create `v2/paths/snapshots.yaml`.
- [x] **Port `/v2/system-info`**: Create `v2/paths/system-info.yaml`.
- [x] **Port `/v2/system-recovery-keys`**: Create `v2/paths/system-recovery-keys.yaml`.
- [x] **Port `/v2/users`**: Create `v2/paths/users.yaml`.
- [x] **Port `/v2/validation-sets`**: Create `v2/paths/validation-sets.yaml`.
- [x] **Port `/v2/validation-sets-name`**: Create `v2/paths/validation-sets-name.yaml`.
- [x] **Port `/v2/warnings`**: Create `v2/paths/warnings.yaml`.

---

## Phase 3: Write command line tools to support use (COMPLETE)

This phase is composed of writing a series of BASH functions to make it easier to utilize the benefits of having our documentation in OpenAPI. The script requirements are:
- (-g, --generate <lang>) &rarr; Requires a programming language as a command line argument. Uses 
- (-h, --help) &rarr; Displays all command line arguments supported by the script.
- (-i, --install) &rarr; Installs all dependencies needed by the script. The following packages are required for the command line to work.
    - Python3
    - Python3-venv
    - NPM
    - NVM
    - NodeJS V22
    - OpenAPI-spec-validator (via Python3-venv)
    - ReDocly
    - Swagger UI CLI (via NPM)
    - PRISM CLI (via NPM)
      - NOTE: DO NOT run this as sudo. If sudo is required for the install to complete (ex. via APT), the system will prompt you. 
- (-p, --prompt) &rarr; Format a prompt for passing to an LLM. Includes:
  - The directory structure.
  - All file names. (with respective contents displayed below)
  - The project README file.
- (-s, --swagger) &rarr; Uses the SWAGGER UI CLI tool to generate a HTTP page displaying the documentation.
- (-v, --validate) &rarr; Use the tool OpenAPI-Spec-Validator to validate that the documentation syntax is valid.
    - NOTE: If an error is present anywhere in the project, it just returns that the error is in the top level directory.

---

## Phase 4: Validate ported documentation is valid (IN-PROGRESS)

This phase involves checking the ported endpoints and comparing them to the existing specification to ensure they have similar coverage of the source content. While completing this for the OpenAPI specification, the following discrepancies were noted and addressed.

### 4.1: Added Components

#### 4.1.1 Parameters
- [x] **Added `UserId`**: Create `v2/components/parameters/UserId.yaml`.

#### 4.1.2 Rules
- [x] **Added `Rule`**: Create `v2/components/rules/Rule.yaml`.
- [x] **Added `RuleActionAdd`**: Create `v2/components/rules/RuleActionAdd.yaml`.
- [x] **Added `RuleActionPatch`**: Create `v2/components/rules/RuleActionPatch.yaml`.
- [x] **Added `RuleActionRemove`**: Create `v2/components/rules/RuleActionRemove.yaml`.
- [x] **Added `RuleActionRemoveById`**: Create `v2/components/rules/RuleActionRemoveById.yaml`.

#### 4.1.3 Schemas

#### 4.1.4 Security
- [x] **Added `macaroonAuth`**: Create `v2/components/security/Macaroon.yaml`.
- [x] **Added `rootAuth`**: Create `v2/components/security/Root.yaml`.

#### 4.2 Added Paths
- [x] **Port `/v2/interfaces/requests/prompts`**: Create `v2/paths/prompts.yaml`.
- [x] **Port `/v2/interfaces/requests/prompts/{id}`**: Create `v2/paths/prompts-id.yaml`.
- [x] **Port `/v2/interfaces/requests/rules`**: Create `v2/paths/rules.yaml`.
- [x] **Port `/v2/interfaces/requests/rules/{id}`**: Create `v2/paths/rules-id.yaml`.
- [x] **Port `/v2/snapshots/{set-id}/export`**: Create `v2/paths/set-id-export.yaml`.
- [x] **Port `/v2/systems`**: Create `v2/paths/systems.yaml`.
- [x] **Port `/v2/systems/{label}`**: Create `v2/paths/systems-label.yaml`.


#### 4.3 Added Script Functionality
- [x] **Added `(-c, --csv)`**: Create `scripts/report_generator.py`, allows for the creation of a summary .csv file containing all endpoints and thier associated request type, used for spot-checking.
- [x] **Added `(-d, --graph [--dark])`**: Create `scripts/graph_generator.py`, allows for generation of a light or dark mode representation of connections between paths, and the components they rely on.
- [x] **Added `(-m, --mock-server)`**: Attempts to launch a mock server through the bash script. **UNTESTED**
- [x] **Added `(--sphinx [dir])`**: Attempts to convert the generated swagger HTML file into an embedding for the Sphinx document generator.

---

#### 4.4 Added Continious Integration
- [x] **Added `CI Workflow`**: Create `.github/workflows/openapi-ci.yaml`.

This workflow will run on every PR request, and will ensure that the core functionality of the controller script is working, and validate that the OpenAPi spec is valid, and that generation of certain outputs occurs without errors.

---

## Phase 5: Upgrade from OpenAPI Spec v3.0.4 to v3.1.0 (NOT-COMPLETE)

This phase will likely require rewrites of the schema system, which now supports modern JSON schema. [Upgrading to 3.1.0](https://www.openapis.org/blog/2021/02/16/migrating-from-openapi-3-0-to-3-1-0)

---

## Phase 6: Continuous Development (Ongoing)

The current understanding I have is that the Snapd REST API page [here](https://snapcraft.io/docs/snapd-api) is based-off a series of forum posts. Currently there is not any code that updates the OpenAPI pages based on the forum post content. There are three ways to proceed.
1. Adapt the scripts embedded in the REST API webpage.
2. Create a new procedure for updating documentation.
3. Port the SnapD project to use the generated API that comes from the OpenAPI Specification. That way the documentation of our project drives the design, and the process of validation, generation, etc could be implemented using CI.