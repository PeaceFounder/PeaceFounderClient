using AppBundler

import TOML
import Pkg.BinaryPlatforms: Linux, MacOS, Windows

APP_DIR = dirname(@__DIR__)

BUILD_DIR = joinpath(APP_DIR, "build")
mkpath(BUILD_DIR)

VERSION = TOML.parsefile("$APP_DIR/Project.toml")["version"]

AppBundler.bundle_app(MacOS(:x86_64), APP_DIR, "$BUILD_DIR/peacefounder-$VERSION-x64.app")
AppBundler.bundle_app(MacOS(:aarch64), APP_DIR, "$BUILD_DIR/peacefounder-$VERSION-arm64.app")

AppBundler.bundle_app(Linux(:x86_64), APP_DIR, "$BUILD_DIR/peacefounder-$VERSION-x64.snap")
AppBundler.bundle_app(Linux(:aarch64), APP_DIR, "$BUILD_DIR/peacefounder-$VERSION-arm64.snap")

AppBundler.bundle_app(Windows(:x86_64), APP_DIR, "$BUILD_DIR/peacefounder-$VERSION-x64.zip"; path_length_threshold = 180, skip_long_paths = true)
