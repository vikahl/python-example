# Example Docker image that uses a multistage build to first build the a
# library of the service.

FROM python:slim AS builder
# It is recommended to use sha256 hash to ensure exact version, as tags can be
# moved. For example:
# FROM python:slim@sha256:a7deebfd654d0158999e9ae9a78ce4a9c7090816a2d1600d254fef8b7fd74cac
# The tag ("slim") is ignored when the hash ("sha256:…") is used but it makes
# it easier for humans to read which image is used.
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
# It is recommended to use sha256 here as well (see comment at builder FROM
# statement).
FROM python:slim AS runtime

# Create a user and group to not run everything as root.
RUN groupadd --gid 1000 --system python_project_example && \
    useradd --uid 1000 --system python_project_example -g python_project_example -s /sbin/nologin

# Copy the wheel file from the builder
COPY --chown=1000:1000 --from=builder /app/dist/ dist/

# Install the library without dependencies, as we are using the compiled
# dependencies in "requirements.txt" to pin all versions.
# Use --no-index and --find-links to have pip look for the module/wheel file in
# the local directory tree.
RUN pip3 install --no-cache-dir --no-deps --no-index --find-links=dist python_project_example \
  && rm -rf dist/

# Copy the compiled requirements and install them. See the two alternatives for
# different type of packages.
COPY --chown=1000:1000 requirements.txt .

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
USER python_project_example

# Copy the run.py entrypoint.
# One alternative solution is to specify an entrpoint in pyproject.toml and run
# the service as a cli command. This needs to be modified if the service is
# started with another command (e.g., gunicorn).
COPY --chown=1000:1000 src/run.py .

# Run the service. This needs to be modified if the service is started with
# another command (e.g., gunicorn).
CMD python3 run.py
