FROM docker.io/library/eclipse-temurin:11-jre@sha256:03cd7f5583a8ba659923a311b8a2452a9786bc275b808a5d7359f677bdf4e6a2
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008,DL3028
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl sshpass ruby-full build-essential zlib1g-dev && \
    curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    gem install jekyll bundler

ENV PUBLISHER_VERSION=1.2.38
ENV PUBLISHER_DOWNLOAD_URL="https://github.com/HL7/fhir-ig-publisher/releases/download/${PUBLISHER_VERSION}/publisher.jar"

ENV SUSHI_VERSION=2.9.0
RUN npm install -g fsh-sushi@${SUSHI_VERSION} && \
    curl -LSs $PUBLISHER_DOWNLOAD_URL --output /usr/local/bin/publisher.jar && \
    chmod +x /usr/local/bin/publisher.jar

ENV JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"
WORKDIR /usr/src/build
CMD ["/bin/bash"]
