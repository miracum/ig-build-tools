FROM openjdk:11-jre
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008,DL3028
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl sshpass ruby-full build-essential zlib1g-dev && \
    curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    gem install jekyll bundler

ENV PUBLISHER_VERSION=1.1.84
ENV PUBLISHER_DOWNLOAD_URL="https://github.com/HL7/fhir-ig-publisher/releases/download/${PUBLISHER_VERSION}/publisher.jar"

ENV SUSHI_VERSION=2.1.1
RUN npm install -g fsh-sushi@${SUSHI_VERSION} && \
    curl -LSs $PUBLISHER_DOWNLOAD_URL --output /usr/local/bin/publisher.jar && \
    chmod +x /usr/local/bin/publisher.jar

ENV JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"
WORKDIR /usr/src/build
CMD ["/bin/bash"]
