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
