#!/bin/bash
#
# Compile and run a small boost + spdlog + fmt program with both toolchains inside the image.
# Usage: ./smoke-test.sh [IMAGE]   (default: psedoc/cpp-devcontainer:latest)
#
set -euo pipefail

IMAGE=${1:-psedoc/cpp-devcontainer:latest}

docker run --rm -i "$IMAGE" bash -euo pipefail <<'EOS'
clang-23 --version | head -1
g++-14 --version | head -1
cmake --version | head -1
echo "Debian $(cat /etc/debian_version)"

cd /tmp
cat > t.cpp <<'EOF'
#include <boost/url.hpp>
#include <spdlog/spdlog.h>
int main() {
    auto u = boost::urls::parse_uri("https://example.org/a");
    spdlog::info("host={}", std::string(u->host()));
}
EOF
# spdlog was built with SPDLOG_FMT_EXTERNAL; its CMake target would add these defines
D="-DSPDLOG_FMT_EXTERNAL -DSPDLOG_COMPILED_LIB"

echo "== gcc + libstdc++ (/usr/local)"
g++-14 -std=c++23 $D t.cpp -lboost_url -lspdlog -lfmt -o t-gcc
./t-gcc

echo "== clang + libc++ (/opt/libc++)"
clang++-23 -std=c++23 -stdlib=libc++ -Wno-deprecated-declarations $D -I/opt/libc++/include t.cpp \
    -L/opt/libc++/lib -Wl,-rpath,/opt/libc++/lib -lboost_url -lspdlog -lfmt -o t-clang
./t-clang
echo "OK"
EOS
