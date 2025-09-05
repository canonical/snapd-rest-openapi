# Use a Node.js base image
FROM ubuntu:noble

# Set the default working directory for any commands run in this container
WORKDIR /docs

# Install the swagger-ui-cli tool globally so it's available on the PATH
RUN npm install -g swagger-ui-cli
