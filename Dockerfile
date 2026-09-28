#
# https://github.com/devcontainers/images/tree/main/src/base-debian/README.md
#
ARG VARIANT=trixie
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
ARG LLVM_VERSION=23
ARG LLVM_GPG_FINGERPRINT=6084F3CF814B57C1CF12EFD515CF4D18AF4F7421
RUN wget -q -O - https://apt.llvm.org/llvm-snapshot.gpg.key | \
        gpg --dearmor -o /etc/apt/trusted.gpg.d/llvm-snapshot.gpg && \
    echo "deb http://apt.llvm.org/${VARIANT}/ llvm-toolchain-${VARIANT}-${LLVM_VERSION} main" \
        >> /etc/apt/sources.list.d/llvm-snapshot.list && \
    sed -i 's/^\(sha1.second_preimage_resistance\).*=.*/\1 = 2026-12-31/' \
        /usr/share/apt/default-sequoia.config && \
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
       libxml2-dev libcunit1-dev libev-dev libssl-dev libc-ares-dev libevent-dev liburing-dev \
       libpcap-dev socat netcat-openbsd tcpdump tcpflow \
       make binutils autoconf automake autotools-dev libtool pkg-config \
       zlib1g-dev libjansson-dev libjemalloc-dev libsystemd-dev bison libelf-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#
# GCC: latest version available in Debian (trixie: 14)
#
ARG GCC_VERSION=14
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && \
    apt-get -y install --no-install-recommends \
        gcc-${GCC_VERSION} g++-${GCC_VERSION} libstdc++-${GCC_VERSION}-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#
# Compiled libraries (boost, fmt, googletest) are built twice, as libc++ and libstdc++
# are not ABI compatible:
#
# 1) clang + libc++      --> /opt/libc++   (use -DCMAKE_PREFIX_PATH=/opt/libc++)
# 2) gcc   + libstdc++   --> /usr/local    (default, found automatically)
#
ARG LIBCXX_PREFIX=/opt/libc++

#
# build recent boost
#
# https://stackoverflow.com/questions/8486077/how-to-compile-link-boost-with-clang-libc
#
ARG BV=1.92.0
RUN wget -vv https://github.com/boostorg/boost/releases/download/boost-${BV}/boost-${BV}-cmake.tar.xz && \
    tar xJf boost-${BV}-cmake.tar.xz && \
    rm boost-${BV}-cmake.tar.xz && \
    cd boost-${BV}* && \
    ./bootstrap.sh --with-toolset=clang && \
    sed -i "s/using clang ;/using clang : ${LLVM_VERSION} : clang++-${LLVM_VERSION} ;/" project-config.jam && \
    echo "using gcc : ${GCC_VERSION} : g++-${GCC_VERSION} ;" >> project-config.jam && \
    BOOST_LIBS="--with-thread --with-date_time --with-regex --with-serialization \
        --with-filesystem --with-coroutine --with-url --with-cobalt --with-program_options \
        --with-process" && \
    ./b2 toolset=clang-${LLVM_VERSION} cxxflags="-std=c++23 -stdlib=libc++" linkflags="-stdlib=libc++" -j 20 \
        --build-dir=build-libc++ --prefix=${LIBCXX_PREFIX} \
        $BOOST_LIBS install && \
    ./b2 toolset=gcc-${GCC_VERSION} cxxflags="-std=c++23" -j 20 \
        --build-dir=build-libstdc++ --prefix=/usr/local \
        $BOOST_LIBS install && \
    cd .. && \
    rm -rf boost-${BV}*

#
# recent CMake
#
ARG CMAKE_VERSION=4.4.2
RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh -q -O /tmp/cmake-install.sh && \
    chmod u+x /tmp/cmake-install.sh && \
    mkdir /opt/cmake-${CMAKE_VERSION} && \
    /tmp/cmake-install.sh --skip-license --prefix=/opt/cmake-${CMAKE_VERSION} && \
    rm /tmp/cmake-install.sh && \
    ln -s /opt/cmake-${CMAKE_VERSION}/bin/* /usr/local/bin

# ENV CC="/usr/bin/clang-${LLVM_VERSION}" \
#     CXX="/usr/bin/clang++-${LLVM_VERSION}" \
#     COV="/usr/bin/llvm-cov-${LLVM_VERSION}" \
#     LLDB="/usr/bin/lldb-${LLVM_VERSION}"

#
# libc++, needed for cppcoro
# be aware of https://stackoverflow.com/questions/56738708/c-stdbad-alloc-on-stdfilesystempath-append
#
# ENV CXXFLAGS="-stdlib=libc++"
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
# FIXME: Drop support for this and use std::format instead.
#
# ARG FMT_VERSION=10.2.1
# ARG FMT_VERSION=11.1.4
ARG FMT_VERSION=12.2.0
RUN wget https://github.com/fmtlib/fmt/releases/download/${FMT_VERSION}/fmt-${FMT_VERSION}.zip && \
    unzip fmt-${FMT_VERSION}.zip && \
    cd fmt-${FMT_VERSION} && \
    cmake -S . -B build-libc++ -G Ninja -DFMT_TEST=no -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_COMPILER=clang++-${LLVM_VERSION} \
        -DCMAKE_CXX_FLAGS="-stdlib=libc++" \
        -DCMAKE_INSTALL_PREFIX=${LIBCXX_PREFIX} && \
    cmake --build build-libc++ --target install && \
    cmake -S . -B build-libstdc++ -G Ninja -DFMT_TEST=no -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_COMPILER=g++-${GCC_VERSION} \
        -DCMAKE_INSTALL_PREFIX=/usr/local && \
    cmake --build build-libstdc++ --target install && \
    cd .. && rm -rf fmt-${FMT_VERSION}.zip fmt-${FMT_VERSION}

#
# spdlog
#
# https://github.com/gabime/spdlog
#
# Uses the external fmt from the matching prefix instead of the bundled one.
#
# v1.17.0
ARG SPDLOG_COMMIT=79524ddd08a4ec981b7fea76afd08ee05f83755d
RUN git clone https://github.com/gabime/spdlog.git && \
    cd spdlog && \
    git checkout ${SPDLOG_COMMIT} && \
    cmake -S . -B build-libc++ -G Ninja -DCMAKE_BUILD_TYPE=Release -DSPDLOG_FMT_EXTERNAL=ON \
        -DCMAKE_CXX_COMPILER=clang++-${LLVM_VERSION} \
        -DCMAKE_CXX_FLAGS="-stdlib=libc++" \
        -DCMAKE_PREFIX_PATH=${LIBCXX_PREFIX} \
        -DCMAKE_INSTALL_PREFIX=${LIBCXX_PREFIX} && \
    cmake --build build-libc++ --target install && \
    cmake -S . -B build-libstdc++ -G Ninja -DCMAKE_BUILD_TYPE=Release -DSPDLOG_FMT_EXTERNAL=ON \
        -DCMAKE_CXX_COMPILER=g++-${GCC_VERSION} \
        -DCMAKE_INSTALL_PREFIX=/usr/local && \
    cmake --build build-libstdc++ --target install && \
    cd .. && rm -rf spdlog

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
    cmake -S . -B build-libc++ -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER=clang-${LLVM_VERSION} \
        -DCMAKE_CXX_COMPILER=clang++-${LLVM_VERSION} \
        -DCMAKE_CXX_FLAGS="-stdlib=libc++" \
        -DCMAKE_INSTALL_PREFIX=${LIBCXX_PREFIX} && \
    cmake --build build-libc++ --target install && \
    cmake -S . -B build-libstdc++ -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER=gcc-${GCC_VERSION} \
        -DCMAKE_CXX_COMPILER=g++-${GCC_VERSION} \
        -DCMAKE_INSTALL_PREFIX=/usr/local && \
    cmake --build build-libstdc++ --target install && \
    cd .. && rm -rf googletest

#
# gtest-parallel
#
RUN cd /opt && \
    git clone https://github.com/google/gtest-parallel.git && \
    cd /usr/local/bin && \
    ln -s /opt/gtest-parallel/gtest-parallel

# -------------------------------------------------------------------------------------------------

#
# GDB pretty printers for libc++
#
ARG USERNAME=vscode
RUN GDB=/usr/local/lib/gdb && \
    mkdir -p $GDB && cd $GDB && \
    wget https://raw.githubusercontent.com/llvm/llvm-project/9a30ada53d5ef8d651c75795af2f6e9c48a1eecb/libcxx/utils/gdb/libcxx/printers.py && \
    cd /home/${USERNAME} && \
    echo >>.gdbinit "python\nimport sys\nsys.path.insert(0, '$GDB')\nfrom printers import register_libcxx_printer_loader\nregister_libcxx_printer_loader()\nend" && \
    chown ${USERNAME} .gdbinit

# -------------------------------------------------------------------------------------------------
