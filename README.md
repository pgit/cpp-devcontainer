# CPP Devcontainer

This repository contains the Dockerfile for building a CPP development container with recent versions of

* LLVM
* Boost
* CMake
* fmt
* range-v3

OS is Debian-13 "trixie".

## [Dockerfile](Dockerfile)

Currently, this is a monolithic image, but I'm following the devcontainer standardization efforts and maybe add support for [features](https://code.visualstudio.com/blogs/2022/09/15/dev-container-features) later.

## [.devcontainer](.devcontainer)

This repository also contains a [.devcontainer](.devcontainer) folder. This is meant as an example on how to use the development container in your own projects. It is not intended to be used for working on this repository, as you don't really need a container to work on a simple [Dockerfile](Dockerfile).

The [.devcontainer/Dockerfile](.devcontainer/Dockerfile) adds a small layer on top of the CPP development images to support persisting bash history in a custom volume.

## Building

```bash
docker build -t psedoc/cpp-devcontainer:VERSION . -t psedoc/cpp-devcontainer:latest
```
A new image will be automatically built on [Docker HUB](https://hub.docker.com/repository/docker/psedoc/cpp-devcontainer/general) when a tag is pushed.
