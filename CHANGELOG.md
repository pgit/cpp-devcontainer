# CHANGELOG.md

## Version 0.17 (2025-09-09)
### Changed
- Updated `llvm` to 21.1.0.

## Version 0.16 (2025-06-06)
### Changed
- Updated `boost` to version 1.89. When using this version, a change to your `CMakeLists.txt` may be becessary: Instead of <br> `find_package(Boost 1.88 COMPONENTS system ...)`, the `system` component must be made optional by using <br> `find_package(Boost 1.88 COMPONENTS ... OPTIONAL_COMPONENTS system ...)`.

## Version 0.15 (2025-06-06)
### Changed
- Updated `llvm` to version 20.1.7.

## Version 0.14 (2025-06-05)
### Fixed
- Remove `/googletest` after installing.
### Added
- Added `gtest-parallel`.

## Version 0.13 (2025-05-29)
### Changed
- Rebuild with latest security updates.
- Updated `boost` to 1.88 and added `boost::process`.
- Updated `CMake` to 3.31.7.

## Version 0.12 (2025-03-16)
### Changed
- Rebuild with latest security updates.
- Updated `CMake` to 3.31.6.

## Version 0.11 (2025-01-05)
### Changed
- Added `program_options` to `boost`.

## Version 0.10 (2024-12-16)
### Changed
- Updated `boost` from 1.86 to 1.87
- Updated `CMake` from 3.30.1 to 3.30.3.
- Updated `llvm` to version 19.1.6

## Version 0.9
### Changed
- Updated `CMake` from 3.30.1 to 3.30.3.
- Updated `llvm` to version 19.1.2

## Version 0.8 (2024-09-04)
### Changed
- Updated `CMake` from 3.30.1 to 3.30.3.
- Updated `boost` from 1.85.0 to 1.86.0.
- Updated `llvm` to version 18.1.8.

## Version 0.7 (2024-07-27)
### Changed
- Updated `CMake` from 3.29.2 to 3.30.1.

## Version 0.6 (2024-03-10)
### Added
- Added `tcpflow` to the set of networking utilities.
### Changed
- Updated `fmtlib` from 10.1.1 to 10.2.1.
- Updated `CMake` from 3.27.1 to 3.29.2.
- Updated `llvm` to version 18.1.0.

## Version 0.4 (2024-01-03)
### Added

- Added Google Test

## Version 0.3 (2024-01-01)
### Added

- Added CHANGELOG.md
