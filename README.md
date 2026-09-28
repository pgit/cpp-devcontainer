# CPP Devcontainer

This repository contains the Dockerfile for building a CPP development container with recent versions of

* LLVM (from [apt.llvm.org](https://apt.llvm.org))
* GCC (latest available in Debian)
* Boost
* CMake
* fmt
* spdlog
* range-v3
* googletest

OS is Debian-13 "trixie".

## Two C++ standard libraries

The image supports both LLVM's `libc++` and GCC's `libstdc++`. These are not ABI compatible: `libc++` places its types in `std::__1`, so code compiled against one library cannot link against compiled libraries built with the other. The compiled dependencies (Boost, fmt, spdlog, googletest) are therefore built twice and installed into separate prefixes:

| Toolchain                 | Prefix         | Usage                                                      |
|---------------------------|----------------|------------------------------------------------------------|
| GCC + `libstdc++`         | `/usr/local`   | default, found automatically                               |
| clang + `libc++`          | `/opt/libc++`  | `-DCMAKE_PREFIX_PATH=/opt/libc++ -DCMAKE_CXX_FLAGS=-stdlib=libc++` |

`/usr/local` holds the `libstdc++` builds because the system default is `libstdc++`, and it is what clang uses too unless `-stdlib=libc++` is given.

Header-only libraries (range-v3) are installed once, into `/usr/local`.

spdlog is built with `SPDLOG_FMT_EXTERNAL=ON`, so it uses the fmt from the same prefix instead of its bundled copy.

Note that `/opt/libc++/lib` is intentionally not registered with `ldconfig`, as its libraries have the same names as those in `/usr/local/lib`. Binaries built against `/opt/libc++` should use an RPATH, which CMake sets for build-tree binaries by default.

## [Dockerfile](Dockerfile)

Currently, this is a monolithic image, but I'm following the devcontainer standardization efforts and maybe add support for [features](https://code.visualstudio.com/blogs/2022/09/15/dev-container-features) later.

## [.devcontainer](.devcontainer)

This repository also contains a [.devcontainer](.devcontainer) folder. This is meant as an example on how to use the development container in your own projects. It is not intended to be used for working on this repository, as you don't really need a container to work on a simple [Dockerfile](Dockerfile).

The [.devcontainer/Dockerfile](.devcontainer/Dockerfile) adds a small layer on top of the CPP development images to support persisting bash history in a custom volume.

## Building

```bash
docker build . -t psedoc/cpp-devcontainer:VERSION  # or
docker build . -t psedoc/cpp-devcontainer:latest
```
A new image will be automatically built on [Docker HUB](https://hub.docker.com/repository/docker/psedoc/cpp-devcontainer/general) when a tag is pushed.
