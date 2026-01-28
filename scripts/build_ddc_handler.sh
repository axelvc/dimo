#!/bin/bash
set -e

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
RUST_DIR="$PROJECT_DIR/ddc_handler"
LIBRARIES_DIR="$PROJECT_DIR/dimmit/Libraries"
CBINDGEN="$HOME/.local/share/cargo/bin/cbindgen"

echo "Building ddc_handler (Release)..."
cd "$RUST_DIR"
cargo build --release --target aarch64-apple-darwin

echo "Copying static library..."
mkdir -p "$LIBRARIES_DIR"
mkdir -p "$LIBRARIES_DIR/include"
cp -f "target/aarch64-apple-darwin/release/libddc_handler.a" "$LIBRARIES_DIR/"
cp -f "ddc_handler.h" "$LIBRARIES_DIR/include/"

echo "✓ ddc_handler build complete"
