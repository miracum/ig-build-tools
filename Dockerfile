FROM docker.io/library/eclipse-temurin:21-jre-noble@sha256:860f93f736431d707b8819de4a269d3a21eb0bb853953d8730ed855ae912fefc
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /opt/ig-build-tools
ENV NO_UPDATE_NOTIFIER=true \
    NODE_ENV=production \
    JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8" \
    NODE_MAJOR=22 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    PATH="$PATH:/opt/ig-build-tools/node_modules/.bin:/root/.dotnet/tools"

# hadolint ignore=DL3008,DL3028
RUN <<EOF
set -e
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl gnupg sshpass ruby-full build-essential zlib1g-dev dotnet-sdk-8.0
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
apt-get update
apt-get install -y --no-install-recommends nodejs

apt-get clean
rm -rf /var/lib/apt/lists/*

gem install jekyll bundler
EOF

COPY package*.json .
RUN <<EOF
set -e
npm clean-install
sushi --version
EOF

# renovate: datasource=nuget depName=Firely.Terminal packageName=Firely.Terminal
ARG FIRELY_TERMINAL_VERSION=3.3.1
RUN <<EOF
set -e
dotnet tool install --global Firely.Terminal --version ${FIRELY_TERMINAL_VERSION}
fhir --version
EOF

# renovate: datasource=github-releases depName=HL7/fhir-ig-publisher packageName=HL7/fhir-ig-publisher
ARG PUBLISHER_VERSION=1.7.1
ARG PUBLISHER_DOWNLOAD_URL="https://github.com/HL7/fhir-ig-publisher/releases/download/${PUBLISHER_VERSION}/publisher.jar"
RUN <<EOF
curl -LSs "$PUBLISHER_DOWNLOAD_URL" --output /usr/local/bin/publisher.jar
chmod +x /usr/local/bin/publisher.jar
EOF

# renovate: datasource=github-releases depName=hapifhir/org.hl7.fhir.core packageName=hapifhir/org.hl7.fhir.core
ARG VALIDATOR_JAR_VERSION=6.4.0
ARG VALIDATOR_JAR_DOWNLOAD_URL="https://github.com/hapifhir/org.hl7.fhir.core/releases/download/${VALIDATOR_JAR_VERSION}/validator_cli.jar"
RUN <<EOF
curl -LSs "$VALIDATOR_JAR_DOWNLOAD_URL" --output /usr/local/bin/validator_cli.jar
chmod +x /usr/local/bin/validator_cli.jar
EOF

WORKDIR /opt/ig-build-tools/workspace
ENTRYPOINT ["/bin/bash"]
