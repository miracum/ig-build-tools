FROM docker.io/library/eclipse-temurin:21-jre-noble@sha256:ce9014ea8f38b2810e648f8497c2f8d2fa76318a7d476152ce4fddf86ae980d7
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
apt-get install -y --no-install-recommends ca-certificates curl gnupg sshpass ruby-full build-essential zlib1g-dev dotnet-sdk-8.0 git
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
apt-get update
apt-get install -y --no-install-recommends nodejs

apt-get clean
rm -rf /var/lib/apt/lists/*

gem install jekyll bundler
EOF

RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json <<EOF
set -e
npm clean-install
sushi --version
EOF

# renovate: datasource=nuget depName=Firely.Terminal extractVersion=^(?<version>.*)$
ARG FIRELY_TERMINAL_VERSION=3.4.0
RUN <<EOF
set -e
dotnet tool install --global Firely.Terminal --version ${FIRELY_TERMINAL_VERSION}
fhir --version
EOF

# renovate: datasource=github-releases depName=HL7/fhir-ig-publisher
ARG PUBLISHER_VERSION=1.7.1
ARG PUBLISHER_DOWNLOAD_URL="https://github.com/HL7/fhir-ig-publisher/releases/download/${PUBLISHER_VERSION}/publisher.jar"
RUN <<EOF
curl -LSs "$PUBLISHER_DOWNLOAD_URL" --output /usr/local/bin/publisher.jar
chmod +x /usr/local/bin/publisher.jar
EOF

# renovate: datasource=github-releases depName=hapifhir/org.hl7.fhir.core extractVersion=^(?<version>.*)$
ARG VALIDATOR_JAR_VERSION=6.5.21
ARG VALIDATOR_JAR_DOWNLOAD_URL="https://github.com/hapifhir/org.hl7.fhir.core/releases/download/${VALIDATOR_JAR_VERSION}/validator_cli.jar"
RUN <<EOF
curl -LSs "$VALIDATOR_JAR_DOWNLOAD_URL" --output /usr/local/bin/validator_cli.jar
chmod +x /usr/local/bin/validator_cli.jar
EOF

WORKDIR /opt/ig-build-tools/workspace
ENTRYPOINT ["/bin/bash"]
