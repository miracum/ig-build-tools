FROM docker.io/library/eclipse-temurin:11-jre@sha256:3b852bee7f8c641e83b91f831dda6f2de985cb60372489de58fcacb2fa010c9b
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /opt/ig-build-tools
ENV NO_UPDATE_NOTIFIER=true \
    NODE_ENV=production \
    JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8" \
    NODE_MAJOR=20 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    PATH="$PATH:/opt/ig-build-tools/node_modules/.bin:/root/.dotnet/tools"
# hadolint ignore=DL3008,DL3028
RUN <<EOF
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl gnupg sshpass ruby-full build-essential zlib1g-dev dotnet-sdk-6.0
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
apt-get update
apt-get install -y --no-install-recommends nodejs

apt-get clean
rm -rf /var/lib/apt/lists/*

gem install jekyll bundler

dotnet tool install --global Firely.Terminal --version 3.2.0-beta-1
fhir --version
EOF

COPY package*.json .
RUN <<EOF
npm clean-install
sushi --version
EOF

ENV PUBLISHER_VERSION=1.6.11
ENV PUBLISHER_DOWNLOAD_URL="https://github.com/HL7/fhir-ig-publisher/releases/download/${PUBLISHER_VERSION}/publisher.jar"
RUN <<EOF
curl -LSs "$PUBLISHER_DOWNLOAD_URL" --output /usr/local/bin/publisher.jar
chmod +x /usr/local/bin/publisher.jar
EOF

ENV VALIDATOR_JAR_VERSION=6.3.11
ENV VALIDATOR_JAR_DOWNLOAD_URL="https://github.com/hapifhir/org.hl7.fhir.core/releases/download/${VALIDATOR_JAR_VERSION}/validator_cli.jar"
RUN <<EOF
curl -LSs "$VALIDATOR_JAR_DOWNLOAD_URL" --output /usr/local/bin/validator_cli.jar
chmod +x /usr/local/bin/validator_cli.jar
EOF

WORKDIR /opt/ig-build-tools/workspace
ENTRYPOINT ["/bin/bash"]
