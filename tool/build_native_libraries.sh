#!/usr/bin/env bash
# Builds the ua_cryptography library of a ua-cryptography-rust checkout for the targets this machine can build and
# names each file as the GitHub release does, so that a local_library_dir pointing at the output serves every target
# (iOS, Android and a universal macOS build too). The packaging steps mirror ua-cryptography-rust's release.yml.
#
#   tool/build_native_libraries.sh [macos] [ios] [android] [linux]   # default: all this host can build
#
# RUST_REPOSITORY (default ../ua-cryptography-rust) and OUTPUT_DIR (default build/native-libraries) override the
# locations. Android needs cargo-ndk and an NDK (ANDROID_NDK_HOME, or the newest one in the Android SDK).
set -euo pipefail

package_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rust_repository="$(cd "${RUST_REPOSITORY:-$package_root/../ua-cryptography-rust}" && pwd)"
output_dir="${OUTPUT_DIR:-$package_root/build/native-libraries}"
version="$(awk -F'"' '/^\[workspace.package\]/ { inside = 1 } inside && /^version = / { print $2; exit }' \
  "$rust_repository/Cargo.toml")"
mkdir -p "$output_dir"

build() {
  (cd "$rust_repository" && cargo build --release --locked -p ua-cryptography-ffi --lib --target "$1")
}

# rustc writes the build directory as the install name; the changed dylib needs a fresh ad-hoc signature.
place_dylib() {
  local bare="$output_dir/ua-cryptography-$version-$2.dylib"
  cp "$rust_repository/target/$1/release/libua_cryptography.dylib" "$bare"
  install_name_tool -id @rpath/libua_cryptography.dylib "$bare"
  codesign --force --sign - "$bare"
  echo "$bare"
}

build_macos() {
  # The deployment target of the release; cargo's strip breaks the linker of newer Xcode releases.
  export MACOSX_DEPLOYMENT_TARGET=11.0 CARGO_PROFILE_RELEASE_STRIP=none
  build aarch64-apple-darwin && place_dylib aarch64-apple-darwin macos-arm64
  build x86_64-apple-darwin && place_dylib x86_64-apple-darwin macos-x64
  unset MACOSX_DEPLOYMENT_TARGET CARGO_PROFILE_RELEASE_STRIP
}

build_ios() {
  export IPHONEOS_DEPLOYMENT_TARGET=13.0
  build aarch64-apple-ios && place_dylib aarch64-apple-ios ios-arm64
  build aarch64-apple-ios-sim && place_dylib aarch64-apple-ios-sim ios-simulator-arm64
  build x86_64-apple-ios && place_dylib x86_64-apple-ios ios-simulator-x64
  unset IPHONEOS_DEPLOYMENT_TARGET
}

build_android() {
  if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
    local ndk_root="${ANDROID_HOME:-$HOME/Library/Android/sdk}/ndk"
    ANDROID_NDK_HOME="$ndk_root/$(ls "$ndk_root" | sort -V | tail -1)"
    export ANDROID_NDK_HOME
  fi
  local jni_libs="$rust_repository/target/android-jni-libs"
  # API 21 and 16 KB pages, as the release.
  (cd "$rust_repository" && RUSTFLAGS="-C link-arg=-Wl,-z,max-page-size=16384" cargo ndk --platform 21 \
    --output-dir "$jni_libs" -t arm64-v8a -t armeabi-v7a -t x86 -t x86_64 \
    build --release --locked -p ua-cryptography-ffi)
  local abi arch
  for pair in arm64-v8a:arm64 armeabi-v7a:arm x86_64:x64 x86:ia32; do
    abi="${pair%%:*}" arch="${pair#*:}"
    cp "$jni_libs/$abi/libua_cryptography.so" "$output_dir/ua-cryptography-$version-android-$arch.so"
    echo "$output_dir/ua-cryptography-$version-android-$arch.so"
  done
}

build_linux() {
  local arch
  case "$(uname -m)" in
    x86_64) arch=x64 ;;
    aarch64) arch=arm64 ;;
    *) echo "No release target for $(uname -m)" >&2; return 1 ;;
  esac
  (cd "$rust_repository" && cargo build --release --locked -p ua-cryptography-ffi --lib)
  cp "$rust_repository/target/release/libua_cryptography.so" "$output_dir/ua-cryptography-$version-linux-$arch.so"
  echo "$output_dir/ua-cryptography-$version-linux-$arch.so"
}

platforms=("$@")
if [[ ${#platforms[@]} -eq 0 ]]; then
  case "$(uname -s)" in
    Darwin) platforms=(macos ios android) ;;
    Linux) platforms=(linux android) ;;
    *) echo "Build on Windows with cargo build --release -p ua-cryptography-ffi" >&2; exit 1 ;;
  esac
fi
for platform in "${platforms[@]}"; do
  "build_$platform"
done
