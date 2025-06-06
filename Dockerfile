#
# https://github.com/devcontainers/images/tree/main/src/base-debian/README.md
#
ARG VARIANT=bookworm
FROM mcr.microsoft.com/devcontainers/base:${VARIANT}
#
# Debian: update, git, some packages needed for boost
#
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && \
    apt-get -y upgrade && \
    apt-get -y install git bzip2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#
# Latest LLVM (beyond version 7 already installed using apt-get)
#
# https://pspdfkit.com/blog/2020/visual-studio-code-cpp-docker/
#
ARG VARIANT
ARG LLVM_VERSION=20
ARG LLVM_GPG_FINGERPRINT=6084F3CF814B57C1CF12EFD515CF4D18AF4F7421
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/${VARIANT}/ llvm-toolchain-${VARIANT}-${LLVM_VERSION} main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get -y install --no-install-recommends \
        llvm-${LLVM_VERSION} \
        clang-${LLVM_VERSION} \
        lldb-${LLVM_VERSION} \
        libc++-${LLVM_VERSION}-dev \
        libc++abi-${LLVM_VERSION}-dev \
        clang-format-${LLVM_VERSION} \
        clang-tidy-${LLVM_VERSION} \
        clangd-${LLVM_VERSION} \
        lldb-${LLVM_VERSION} \
        libunwind-${LLVM_VERSION}-dev \
        libclang-rt-${LLVM_VERSION}-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ADD llvm-alternatives.sh .
ARG LLVM_VERSION
RUN bash -c "./llvm-alternatives.sh ${LLVM_VERSION}"

#
# other development libraries and network utilities
#
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && \
    apt-get -y install --no-install-recommends \
       ninja-build gdb \
       libxml2-dev libcunit1-dev libev-dev libssl-dev libc-ares-dev libevent-dev zlib1g-dev liburing-dev \
       libpcap-dev socat netcat-openbsd tcpdump tcpflow \
       make binutils autoconf automake autotools-dev libtool pkg-config \
       zlib1g-dev libjansson-dev libjemalloc-dev libsystemd-dev ruby-dev bison libelf-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#
# build recent boost with clang
#
# b2 toolset=clang cxxflags="-std=c++23 -stdlib=libc++" linkflags="-stdlib=libc++"
# https://stackoverflow.com/questions/8486077/how-to-compile-link-boost-with-clang-libc
#
ARG BOOST_VERSION=1.88.0
RUN BV=$(echo "$BOOST_VERSION"|tr . _) && \
    wget https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BV}.tar.bz2 && \
    tar xjf boost_${BV}.tar.bz2 && \
    rm boost_${BV}.tar.bz2 && \
    cd boost_${BV} && \
    ./bootstrap.sh --with-toolset=clang && \
    ./b2 toolset=clang cxxflags="-stdlib=libc++" linkflags="-stdlib=libc++" -j 20 \
        --with-system --with-thread --with-date_time --with-regex --with-serialization \
        --with-filesystem --with-coroutine --with-url --with-cobalt --with-program_options \
        --with-process \
        install && \
    cd .. && \
    rm -rf boost_${BV}

#
# recent CMake
#
ARG CMAKE_VERSION=3.31.7
RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh -q -O /tmp/cmake-install.sh && \
    chmod u+x /tmp/cmake-install.sh && \
    mkdir /opt/cmake-${CMAKE_VERSION} && \
    /tmp/cmake-install.sh --skip-license --prefix=/opt/cmake-${CMAKE_VERSION} && \
    rm /tmp/cmake-install.sh && \
    ln -s /opt/cmake-${CMAKE_VERSION}/bin/* /usr/local/bin

ENV CC="/usr/bin/clang-${LLVM_VERSION}" \
    CXX="/usr/bin/clang++-${LLVM_VERSION}" \
    COV="/usr/bin/llvm-cov-${LLVM_VERSION}" \
    LLDB="/usr/bin/lldb-${LLVM_VERSION}"

#
# libc++, needed for cppcoro
# be aware of https://stackoverflow.com/questions/56738708/c-stdbad-alloc-on-stdfilesystempath-append
#
ENV CXXFLAGS="-stdlib=libc++"
# ENV CXXFLAGS="-stdlib=libc++ -fsanitize=thread -fno-omit-frame-pointer"
# ENV LDFLAGS="-stdlib=libc++"
# ENV LDFLAGS="--fsanitize=thread"

# -------------------------------------------------------------------------------------------------

#
# fmt
#
# FIXME: With LLVM, there are warnings about specializing in namespace std.
#        Added -DFMT_TEST=no to skip building the tests.
#
# ARG FMT_VERSION=11.1.4
ARG FMT_VERSION=10.2.1
RUN wget https://github.com/fmtlib/fmt/releases/download/${FMT_VERSION}/fmt-${FMT_VERSION}.zip && \
    unzip fmt-${FMT_VERSION}.zip && \
    cd fmt-${FMT_VERSION} && \
    mkdir build && \
    cd build && \
    cmake -DFMT_TEST=no .. && \
    make -j 20 install && \
    cd ../.. && rm -rf fmt-${FMT_VERSION}.zip fmt-${FMT_VERSION}

#
# fmtlog
#
# ARG FMTLOG_VERSION=2.2.1
# RUN git clone https://github.com/MengRao/fmtlog.git && \
#     cd fmtlog && \
#     git submodule init && \
#     git submodule update && \
#     ./build.sh && \
#     cp fmtlog.h /usr/include && \
#     cp .build/libfmtlog-* /usr/lib && \
#     cd .. && rm -rf fmtlog

#
# cppcoro
#
# RUN git clone https://github.com/andreasbuhr/cppcoro && \
#     cd cppcoro && \
#     mkdir build && \
#     cd build && \
#     cmake -GNinja .. && \
#     ninja install && \
#     cd ../.. && rm -rf cppcoro

#
# range-v3
#
RUN git clone https://github.com/ericniebler/range-v3.git && \
    cp -ar range-v3/include /usr/local/include/range-v3 && \
    rm -rf range-v3

#
# googletest
#
RUN git clone https://github.com/google/googletest.git && \
    cd googletest && \
    mkdir build && \
    cd build && \
    cmake .. &&  \
    make install && \
    rm -rf googletest

#
# gtest-parallel
#
RUN cd /opt && \
    git clone https://github.com/google/gtest-parallel.git && \
    cd /usr/local/bin && \
    ln -s /opt/gtest-parallel/gtest-parallel

# -------------------------------------------------------------------------------------------------
