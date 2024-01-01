# syntax=docker/dockerfile:1.4
FROM docker.io/library/eclipse-temurin:11-jre@sha256:cfba8df9620f10a0e8b6a147a9a1a09dfce2477a9cb4552dfe94bc7319aa3032
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /opt/ig-build-tools
ENV NO_UPDATE_NOTIFIER=true \
    NODE_ENV=production \
    JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8" \
    NODE_MAJOR=18

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
dotnet tool install --global Firely.Terminal --version 3.1.0
EOF

COPY package*.json .
RUN npm clean-install

ENV PUBLISHER_VERSION=1.5.2
ENV PUBLISHER_DOWNLOAD_URL="https://github.com/HL7/fhir-ig-publisher/releases/download/${PUBLISHER_VERSION}/publisher.jar"
RUN <<EOF
curl -LSs "$PUBLISHER_DOWNLOAD_URL" --output /usr/local/bin/publisher.jar
chmod +x /usr/local/bin/publisher.jar
EOF

ENV PATH="$PATH:/opt/ig-build-tools/node_modules/.bin:/root/.dotnet/tools"
WORKDIR /opt/ig-build-tools/workspace
ENTRYPOINT ["/bin/bash"]
