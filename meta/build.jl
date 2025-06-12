using AppBundler

import TOML
import Pkg.BinaryPlatforms: Linux, MacOS, Windows

APP_DIR = dirname(@__DIR__)

BUILD_DIR = joinpath(APP_DIR, "build")
mkpath(BUILD_DIR)

VERSION = TOML.parsefile("$APP_DIR/Project.toml")["version"]

#AppBundler.build_app(MacOS(:x86_64), APP_DIR, "$BUILD_DIR/peacefounder-$VERSION-x64.dmg")
AppBundler.build_app(MacOS(:aarch64), APP_DIR, "$BUILD_DIR/peacefounder-$VERSION-arm64.dmg"; pfx_path=nothing)

#AppBundler.build_app(Linux(:x86_64), APP_DIR, "$BUILD_DIR/peacefounder-$VERSION-x64.snap")
#AppBundler.build_app(Linux(:aarch64), APP_DIR, "$BUILD_DIR/peacefounder-$VERSION-arm64"; incremental=true, precompile=false)

#AppBundler.build_app(Windows(:x86_64), APP_DIR, "$BUILD_DIR/peacefounder-$VERSION-x64-win"; path_length_threshold = 180, skip_long_paths = true)

#AppBundler.build_app(Windows(:x86_64), APP_DIR, joinpath(homedir(), "Documents", "peacefounder-$VERSION-x64-win.msix"); path_length_threshold = 180, skip_long_paths = true, precompile=false, pfx_path=nothing)
