# ig-build-tools

A container image including useful tools for building FHIR implementation guides.

## Run

Mount a local file system containing a FHIR Shorthand project:

```sh
docker run --rm -it -v $PWD/example/:/usr/src/build ghcr.io/miracum/ig-build-tools:latest
```

Then within the container:

```sh
$ sushi .
# ...
$ java -jar /usr/local/bin/publisher.jar -ig ig.ini
# ...
```
