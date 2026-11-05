# CLAUDE.md

This repo builds the `psedoc/cpp-devcontainer` image from [Dockerfile](Dockerfile). See [README.md](README.md).

## Releasing a new version

Versions are `0.N`. The next version is the newest entry in [CHANGELOG.md](CHANGELOG.md) plus one.

1. **Check for updates:** run `./check-versions.sh`. It compares every `ARG` pin with upstream:
   - `VARIANT`: Debian stable codename (also needs a matching `mcr.microsoft.com/devcontainers/base` tag).
   - `LLVM_VERSION` / `GCC_VERSION`: these pin the major version only. LLVM uses the latest stable major
     (the newest GitHub release, which matches the apt.llvm.org "stable" branch). GCC uses the highest
     `g++-N` in Debian `$VARIANT` / `$VARIANT-backports`.
   - `BV`, `CMAKE_VERSION`, `FMT_VERSION`: latest non-prerelease GitHub release (skip RCs and betas
     unless the user asks for them).
   - `SPDLOG_COMMIT`: commit of the latest release tag. Update the `# vX.Y.Z` comment above it too.
   - Not pinned: range-v3, googletest and gtest-parallel come from git HEAD. The GDB printers
     `printers.py` are pinned to an llvm-project commit, which is left alone.
2. **Update the Dockerfile** `ARG`s that changed. A major LLVM/GCC bump can break the boost/fmt/spdlog
   builds, so read the build log closely.
3. **Build** from scratch so the apt layers pick up the newest LLVM branch snapshot and Debian updates
   (takes a while; run it in the background and log to a file):
   ```bash
   docker build --pull --no-cache -t psedoc/cpp-devcontainer:0.N -t psedoc/cpp-devcontainer:latest .
   ```
4. **Verify** with `./smoke-test.sh psedoc/cpp-devcontainer:0.N`. It prints the installed versions
   (use them in the CHANGELOG), then builds and runs a boost/spdlog/fmt program with gcc+libstdc++ and
   with clang+libc++. Adjust `clang-23` / `g++-14` in the script after a major bump. The apt.llvm.org branch build reports the upcoming point release (e.g. `23.1.6` before it is
   tagged). The CHANGELOG uses that reported number.
5. **CHANGELOG.md:** add `## Version 0.N (YYYY-MM-DD)` at the top with `### Changed` (or Added, Removed,
   Fixed). Write "Updated `X` to V." for pin bumps and "Rebuilt with `llvm` V." for the LLVM point
   version.
6. **Ask the user before committing.** Commit message style: `CMake 4.4.5, llvm 23.1.4 rebuild, v0.31`.
   Docker Hub builds automatically when a git tag (`v0.N`) is pushed, so only create or push the git
   tag when the user says so.
7. **Never push containers.** Tagging locally as `0.N` and `latest` is all that's needed.
