#!/bin/bash
set -e

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
RUST_DIR="$PROJECT_DIR/ddc_handler"
LIBRARIES_DIR="$PROJECT_DIR/dimmit/Libraries"
CBINDGEN="$HOME/.local/share/cargo/bin/cbindgen"

echo "Building ddc_handler (Release)..."
mkdir -p "$LIBRARIES_DIR"
mkdir -p "$LIBRARIES_DIR/include"
cd "$RUST_DIR"
cargo build --release --target aarch64-apple-darwin
cargo build --release --target x86_64-apple-darwin

echo "Creating universal static library..."
lipo -create \
	"target/aarch64-apple-darwin/release/libddc_handler.a" \
	"target/x86_64-apple-darwin/release/libddc_handler.a" \
	-output "$LIBRARIES_DIR/libddc_handler.a"

echo "Copying header..."
cp -f "ddc_handler.h" "$LIBRARIES_DIR/include/"

echo "✓ ddc_handler build complete"
