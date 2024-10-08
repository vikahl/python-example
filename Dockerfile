# Example Docker image that uses a multistage build to first build the a
# library of the service.

FROM python:3.8-slim@sha256:314bc2fb0714b7807bf5699c98f0c73817e579799f2d91567ab7e9510f5601a5 AS builder
# It is recommended to use sha256 hash to ensure exact version, as tags can be
# moved. The tag ("slim") is ignored by Docker when the hash ("sha256:…") is
# used but it allows Dependabot to skip update across minor versions (e.g.,
# update from 3.8 to 3.10) and makes it easier for humans to read which image
# is used.
#
# If you want dependabot to update from e.g., 3.8 to 3.10, update the config in
# .github/dependabot.yaml
#
# It is however hard to maintain and update this in the template, which is why
# it specifies with tags.

# Specify a workdir
WORKDIR /app

# Copy the full repo with all files. These will not be part of the resulting
# image, only the builder.
COPY . .

# To get completely reproducible builds, "build" needs to be pinned, but it is
# stable enough to not do this for normal usage.
RUN pip3 install --no-cache-dir build

# Build the library.
RUN python3 -m build --wheel .

################################################################################
# Start the runtime image.
# See the notes at builder FROM statement about sha256 hashes and automatic updates.
FROM python:3.8-slim@sha256:314bc2fb0714b7807bf5699c98f0c73817e579799f2d91567ab7e9510f5601a5 AS runtime

# Create a user and group to not run everything as root.
RUN groupadd --gid 1000 --system python_example && \
    useradd --uid 1000 --system python_example -g python_example -s /sbin/nologin

# Copy the wheel file from the builder
COPY --chown=1000:1000 --from=builder /app/dist/ dist/

# Install the library without dependencies, as we are using the compiled
# dependencies in "requirements.txt" to pin all versions.
# Use --no-index and --find-links to have pip look for the module/wheel file in
# the local directory tree.
RUN pip3 install --no-cache-dir --no-deps --no-index --find-links=dist python_example \
  && rm -rf dist/

# Copy the compiled requirements and install them. See the two alternatives for
# different type of packages.
COPY --chown=1000:1000 requirements/requirements-py38.txt requirements.txt

# ALTERNATIVE 1: If the packages requires system dependencies (e.g., compilers)
# they can be installed and removed within the same layer to keep the
# dockerfile smaller.
# RUN apt-get update \
#   && apt-get install -y --no-install-recommends build-essential \
#   && rm -rf /var/lib/apt/lists/* \
# Use --no-deps as the requirements-file already contains all dependencies (as it is a compiled file).
# Require hashes to ensure no meddling occurs.
#   && pip3 install --no-deps --require-hashes --no-cache-dir -r requirements.txt \
#   && rm requirements.txt \
#   && apt-get purge -y build-essential

# ALTERNATIVE 2: Just install them
# Use --no-deps as the requirements-file already contains all dependencies (as it is a compiled file).
# Require hashes to ensure no meddling occurs.
RUN pip3 install --no-deps --require-hashes --no-cache-dir -r requirements.txt \
  && rm requirements.txt

# Set the user
USER python_example

# Copy the run.py entrypoint.
# One alternative solution is to specify an entrpoint in pyproject.toml and run
# the service as a cli command. This needs to be modified if the service is
# started with another command (e.g., gunicorn).
COPY --chown=1000:1000 src/run.py .

# Run the service. This needs to be modified if the service is started with
# another command (e.g., gunicorn).
