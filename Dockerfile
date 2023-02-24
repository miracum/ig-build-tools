FROM docker.io/library/eclipse-temurin:11-jre-focal@sha256:6796ce83332a8f6342057197dc3ea9077d0b90189ccc0ac3acbefbba8d7b1583
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008,DL3028
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl sshpass ruby-full build-essential zlib1g-dev && \
    curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    gem install jekyll bundler

ENV PUBLISHER_VERSION=1.2.36
ENV PUBLISHER_DOWNLOAD_URL="https://github.com/HL7/fhir-ig-publisher/releases/download/${PUBLISHER_VERSION}/publisher.jar"

ENV SUSHI_VERSION=2.8.0
RUN npm install -g fsh-sushi@${SUSHI_VERSION} && \
    curl -LSs $PUBLISHER_DOWNLOAD_URL --output /usr/local/bin/publisher.jar && \
    chmod +x /usr/local/bin/publisher.jar

ENV JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"
WORKDIR /usr/src/build
CMD ["/bin/bash"]
