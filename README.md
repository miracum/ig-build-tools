# ig-build-tools

![License](https://img.shields.io/github/license/miracum/ig-build-tools)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/miracum/ig-build-tools/badge)](https://api.securityscorecards.dev/projects/github.com/miracum/ig-build-tools)
[![SLSA 3](https://slsa.dev/images/gh-badge-level3.svg)](https://slsa.dev)

A container image including useful tools for building FHIR implementation guides.

## Run

Mount a local file system containing a FHIR Shorthand project to
the default workspace path at `/opt/ig-build-tools/workspace`:

```sh
docker run --rm -it -v $PWD/example/:/opt/ig-build-tools/workspace ghcr.io/miracum/ig-build-tools:latest
```

Then within the container:

```sh
$ sushi .
# ...
$ java -jar /usr/local/bin/publisher.jar -ig ig.ini
# ...
```

## Available tools

- [SUSHI](https://github.com/FHIR/sushi)
- [Firely.Terminal](https://fire.ly/products/firely-terminal/)
- [IG Publisher](https://github.com/HL7/fhir-ig-publisher)
- [Synthea](https://github.com/synthetichealth/synthea) (`java -jar /usr/local/bin/synthea.jar`)
- [Pathling CLI](https://pathling.csiro.au/docs/libraries/cli) (`pathling`)
- [blazectl](https://github.com/samply/blazectl)

### Pathling CLI

The Spark packages the Pathling CLI needs are already resolved into the Ivy cache at `/opt/ivy`,
so the CLI works without network access. It includes the S3A filesystem, so it can read and
write `s3a://` paths.

Besides root, the CLI runs as any user with an entry in `/etc/passwd`, for example the
`nonroot` user (`--user 65532:65532`). For users without one, Spark fails to start.

Both the Ivy cache and the S3A JARs are configured in `$SPARK_CONF_DIR/spark-defaults.conf`.
If you point `SPARK_CONF_DIR` to your own configuration, copy these settings to it. If you set
`spark.jars` yourself, include `/opt/spark/s3a-jars/*.jar` to keep the S3A filesystem.
