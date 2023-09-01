# syntax=docker/dockerfile:1.4
FROM docker.io/library/eclipse-temurin:11-jre@sha256:fa8625d6fef95cbf887d1e23cb6e32d280da0183f3525e9b50134be50123347e
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /opt/ig-build-tools
ENV NO_UPDATE_NOTIFIER=true \
    NODE_ENV=production \
    PATH="$PATH:/opt/ig-build-tools/node_modules/.bin:/root/.dotnet/tools" \
    JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"

# hadolint ignore=DL3008,DL3028
RUN <<EOF
apt-get update
apt-get install -y --no-install-recommends curl sshpass ruby-full build-essential zlib1g-dev dotnet-sdk-6.0
curl -sL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y --no-install-recommends nodejs
apt-get clean
rm -rf /var/lib/apt/lists/*
gem install jekyll bundler
dotnet tool install --global Firely.Terminal --version 3.1.0
EOF

COPY package*.json .
RUN npm clean-install

ENV PUBLISHER_VERSION=1.4.2
ENV PUBLISHER_DOWNLOAD_URL="https://github.com/HL7/fhir-ig-publisher/releases/download/${PUBLISHER_VERSION}/publisher.jar"
RUN <<EOF
curl -LSs $PUBLISHER_DOWNLOAD_URL --output /usr/local/bin/publisher.jar
chmod +x /usr/local/bin/publisher.jar
EOF

WORKDIR /opt/ig-build-tools/workspace
CMD ["/bin/bash"]
