# snapd-rest-openapi

A work-in-progress reimplementation of the [snapd REST API documentation](https://snapcraft.io/docs/snapd-api) using a subset of the [OpenAPI 3](https://swagger.io/specification/) specification.

[GitHub Pages preview with Swagger](https://degville.github.io/snapd-rest-openapi/).

This work is currently considered highly experimental and is still in the _proof of concept_ phase. The snapd team hopes to use these experiments to improve how the API is documented, and the processes behind API documentation. 

## The current process

The [snapd](https://github.com/canonical/snapd/) REST API documentation is currently manually created and updated whenever there are functional or syntactical changes to the API.

This requires a snapd developer to be aware of the API modifications they make, and to track those changes until they've been merged into the code base. It's then their responsibility to update the REST API documentation manually.

### The current format

The current REST API documentation is written in Markdown, using [markdown-it](https://github.com/markdown-it/markdown-it) and hosted on the [Discourse-based](https://www.discourse.org/) [forum.snapcraft.io](https://forum.snapcraft.io/t/snapd-rest-api/17954). From there, it's published directly to the [official documentation](https://snapcraft.io/docs).

The REST API Markdown file is tightly structured using headings, subheadings, bullets and code blocks. These are manually added and adjusted when the API changes. There is currently no automation, and no testing, and edits often breaks the consistency and output of the source document.

Moving to an OpenAPI-based source document is intended to solve these problems.

## Contents of this repository

The `/yaml` directory contains the current yaml specification for the OpenAPI translation.

The `/original` directory contains the source Markdown file and a _diff_ file containing the source elements that have so-far not been migrated to the OpenAPI yaml file.

## Work still to do

- Review the accuracy of the current specification
  - parameters and properties need particular attention 
  - that request and response examples are in the right place
- Integrate the missing elements from snap_api_diff.md
- Replace json strings with native yaml (some, but not all, have already been done)
- Add better descriptions and summaries
- Review the completeness of the specification
  - examples often contain more fields than are documented (`POST /v2/quotas`)
  - ensure the structure is consistent
- Test the requests, especially from the convenience of the Swagger front-end
