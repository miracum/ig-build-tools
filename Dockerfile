FROM mcr.microsoft.com/dotnet/sdk:8.0-noble@sha256:35f39dc26de234f9bd24d482b8c7a9391d263dfbc1e62f24bb59de1168dd8d21 AS firely-terminal
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
# renovate: datasource=nuget depName=Firely.Terminal extractVersion=^(?<version>.*)$
ARG FIRELY_TERMINAL_VERSION=3.4.0
RUN dotnet tool install --tool-path /opt/firely-terminal Firely.Terminal --version ${FIRELY_TERMINAL_VERSION}

FROM ghcr.io/astral-sh/uv:0.13.6@sha256:af22a52f5eafef3d78e551599d405c02df61919d18028f0cea8eda93bc9986d0 AS uv

FROM docker.io/library/eclipse-temurin:24-jre-noble@sha256:b416d02335e702b0403ff280de9475a3348e29382285969c9d4e17862ce632e7
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /opt/ig-build-tools
ENV NO_UPDATE_NOTIFIER=true \
    NODE_ENV=production \
    JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8" \
    NODE_MAJOR=24 \
    DOTNET_ROOT=/usr/lib/dotnet \
    PATH="$PATH:/opt/ig-build-tools/node_modules/.bin:/opt/firely-terminal"

# hadolint ignore=DL3008,DL3028
RUN <<EOF
set -e
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl gnupg sshpass ruby ruby-dev build-essential zlib1g-dev dotnet-runtime-8.0 git jq python3
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
apt-get update
apt-get install -y --no-install-recommends nodejs

gem install jekyll bundler
# the compilers are only needed to build the gems' native extensions
apt-get purge -y --auto-remove build-essential zlib1g-dev ruby-dev

apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json <<EOF
set -e
npm clean-install
sushi --version
EOF

COPY --from=firely-terminal /opt/firely-terminal /opt/firely-terminal
RUN fhir --version

# renovate: datasource=github-releases depName=HL7/fhir-ig-publisher extractVersion=^(?<version>.*)$
ARG PUBLISHER_VERSION=3.0.1
ARG PUBLISHER_DOWNLOAD_URL="https://github.com/HL7/fhir-ig-publisher/releases/download/${PUBLISHER_VERSION}/publisher.jar"
RUN <<EOF
set -e
curl -LSs "$PUBLISHER_DOWNLOAD_URL" --output /usr/local/bin/publisher.jar
chmod +x /usr/local/bin/publisher.jar
# recent IG templates' _genonce.sh look for the publisher in ${FHIR_PUBLISHER_HOME:-$HOME/.fhir/tools/publisher}
mkdir -p /root/.fhir/tools/publisher
ln -s /usr/local/bin/publisher.jar /root/.fhir/tools/publisher/publisher.jar
EOF

# renovate: datasource=github-releases depName=hapifhir/org.hl7.fhir.core extractVersion=^(?<version>.*)$
ARG VALIDATOR_JAR_VERSION=7.0.2
ARG VALIDATOR_JAR_DOWNLOAD_URL="https://github.com/hapifhir/org.hl7.fhir.core/releases/download/${VALIDATOR_JAR_VERSION}/validator_cli.jar"
RUN <<EOF
set -e
curl -LSs "$VALIDATOR_JAR_DOWNLOAD_URL" --output /usr/local/bin/validator_cli.jar
chmod +x /usr/local/bin/validator_cli.jar
# pre-populate the FHIR package cache (~/.fhir/packages) with the validator's own
# support packages (cross-version extensions, terminology closure packages) that it
# otherwise downloads on first use for any R4 validation run, regardless of which IGs
# are being validated. Baking them into the image avoids a package registry dependency
# during CI runs.
java -jar /usr/local/bin/validator_cli.jar -version 4.0.1 -tx n/a
EOF

# renovate: datasource=github-releases depName=synthetichealth/synthea
ARG SYNTHEA_VERSION=4.0.0
ARG SYNTHEA_DOWNLOAD_URL="https://github.com/synthetichealth/synthea/releases/download/v${SYNTHEA_VERSION}/synthea-with-dependencies.jar"
RUN <<EOF
set -e
curl -LSs "$SYNTHEA_DOWNLOAD_URL" --output /usr/local/bin/synthea.jar
chmod +x /usr/local/bin/synthea.jar
EOF

# renovate: datasource=pypi depName=pathling extractVersion=^(?<version>.*)$
ARG PATHLING_VERSION=10.0.0
RUN --mount=from=uv,source=/uv,target=/usr/local/bin/uv <<EOF
set -e
export UV_TOOL_DIR=/opt/uv/tools UV_TOOL_BIN_DIR=/usr/local/bin
uv tool install --no-cache --no-python-downloads --python /usr/bin/python3 "pathling==${PATHLING_VERSION}"
pathling --version
# the CLI resolves the Pathling library runtime and Delta Lake JARs from Maven Central
# into the Ivy cache (~/.ivy2.5.2) whenever it starts a Spark session. Starting one here
# bakes them into the image, so CI runs don't depend on Maven Central.
pathling run -c "print(spark.version)"
# jars/ only duplicates cache/ (Ivy copies the resolved JARs there again on startup, no
# network needed) and the session leaves another copy of them behind in /tmp
rm -rf /root/.ivy2.5.2/jars /tmp/spark-* /tmp/blockmgr-*
EOF

ARG TARGETARCH
# renovate: datasource=github-releases depName=samply/blazectl
ARG BLAZECTL_VERSION=1.5.1
ARG BLAZECTL_DOWNLOAD_URL="https://github.com/samply/blazectl/releases/download/v${BLAZECTL_VERSION}/blazectl-${BLAZECTL_VERSION}-linux-${TARGETARCH}.tar.gz"
RUN <<EOF
set -e
curl -LSsf "$BLAZECTL_DOWNLOAD_URL" | tar -xz --no-same-owner -C /usr/local/bin blazectl
blazectl --version
EOF

WORKDIR /opt/ig-build-tools/workspace
ENTRYPOINT ["/bin/bash"]
