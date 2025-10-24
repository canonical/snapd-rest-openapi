<!--
    SPDX-FileCopyrightText: 2025 Canonical Ltd
    SPDX-License-Identifier: GPL-3.0-only
-->

# snapd-rest-openapi

A complete reimplementation of the [snapd REST API documentation](https://snapcraft.io/docs/snapd-api) using the [OpenAPI 3](https://swagger.io/specification/) specification.

[GitHub Pages preview with Swagger](https://degville.github.io/snapd-rest-openapi/).

## Existing Process

The [snapd](https://github.com/canonical/snapd/) REST API documentation is manually created and updated whenever there are functional or syntactical changes to the API.

This requires a snapd developer to be aware of the API modifications they make, and to track those changes until they've been merged into the code base. It's then their responsibility to update the REST API documentation manually.

### Existing Format

The existing REST API documentation is written in Markdown, using [markdown-it](https://github.com/markdown-it/markdown-it) and hosted on the [Discourse-based](https://www.discourse.org/) [forum.snapcraft.io](https://forum.snapcraft.io/t/snapd-rest-api/17954). From there, it's published directly to the [official documentation](https://snapcraft.io/docs).

The REST API Markdown file is tightly structured using headings, subheadings, bullets and code blocks. These are manually added and adjusted when the API changes. There is currently no automation, and no testing, and edits often breaks the consistency and output of the source document.

Moving to an OpenAPI-based source document is intended to solve these problems.

## Repository Contents

The repository is structured to modularly build a complete OpenAPI specification. The main `openapi.yaml` file serves as the entry point, referencing the various components defined in the `v2/` directory.

```
.
└── v2
    ├── components
    │   ├── errors
    │   ├── parameters
    │   ├── responses
    │   ├── schemas
    │   └── security
    └── paths
```

The `v2/` directory contains the individual OpenAPI components:

*   **components**: Reusable components like schemas, responses, and security schemes.
    *   **errors**: Defines the various error responses that the API can return.
    *   **parameters**: Defines reusable parameters for API operations.
*   **responses**: Defines reusable responses for API operations.
    *   **schemas**: Defines the data models used in the API.
    *   **security**: Defines the security schemes used by the API.
*   **paths**: The individual API paths, with each file corresponding to an endpoint.

For more detailed information on the project structure and how to update the specification, please see [UPDATING.md](UPDATING.md).

## Ongoing Work

   * openapi.yaml: description: Requires the user to authenticate with root access. # TODO Properly describe the difference between AuthenticationRequired and Root
   * v2/paths/logout.yaml: - PeerAuth: [] # TODO security and responses need to be re-evaluated in another PR
   * v2/paths/validation-sets-name.yaml: operationId: applyValidationSet # TODO, ensure operationId matches SnapD Daemon codebase
   * v2/paths/notices.yaml: security: [] # TODO Not fully described in machine-readable format, normally OpenAccess unless certain parameters are used
   * v2/paths/interfaces.yaml: description: |- # TODO Investigate whether discriminator can be used to map input parameter to oneOf result
   * v2/paths/assertions-type.yaml: description: |- # TODO Look for a way to syntactically document this
   * v2/components/responses/MethodNotAllowed.yaml: # TODO Link to routes that do not define endpoints for certain request types
   * v2/components/responses/Forbidden.yaml: - auth-cancelled # TODO follow up PR looking into kind enum
   * v2/components/schemas/PromptReply.yaml: oneOf: # TODO look into mapping interface name to oneOf instances
   * v2/components/schemas/Prompt.yaml: oneOf: # TODO look into mapping interface name to oneOf instances
   * v2/components/errors/NoModelAssertionError.yaml: - assertion-not-found # TODO Need follow up PR focusing only on errors
   * v2/components/errors/ConfdbError.yaml: - assertion-not-found # TODO Need follow up PR focusing only on errors
   * v2/components/errors/ConflictError.yaml: - manip # TODO investigate change-kinds in follow-up PR
   * v2/components/errors/SnapNotInstalledError.yaml: - snap-not-installed # TODO Need follow up PR focusing only on errors
