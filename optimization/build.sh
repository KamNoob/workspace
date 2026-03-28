#!/bin/bash
set -e

echo "🔨 Building Hybrid Rust + Go Optimization Stack"
echo "=================================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

if ! command -v rustc &> /dev/null; then
    echo -e "${YELLOW}Rust not found. Installing...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
fi

if ! command -v go &> /dev/null; then
    echo -e "${YELLOW}Go not found. Please install Go 1.21+ manually${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites OK${NC}"
echo ""

# Build Rust Indexer
echo -e "${BLUE}Building Rust API Indexer...${NC}"
cd "$SCRIPT_DIR/rust-indexer"

echo "  Installing dependencies..."
cargo fetch --quiet 2>/dev/null || true

echo "  Compiling (release mode)..."
cargo build --release --quiet

RUST_BINARY="$SCRIPT_DIR/rust-indexer/target/release/api-indexer"
if [ -f "$RUST_BINARY" ]; then
    echo -e "${GREEN}✓ Rust indexer built successfully${NC}"
    echo "  Location: $RUST_BINARY"
    echo "  Size: $(ls -lh $RUST_BINARY | awk '{print $5}')"
else
    echo -e "${YELLOW}✗ Rust build failed${NC}"
    exit 1
fi

echo ""

# Build Go Cache Layer
echo -e "${BLUE}Building Go Cache Layer...${NC}"
cd "$SCRIPT_DIR/go-cache"

echo "  Downloading dependencies..."
go mod download 2>&1 | grep -v "^go:" || true

echo "  Compiling..."
go build -o api-cache main.go

GO_BINARY="$SCRIPT_DIR/go-cache/api-cache"
if [ -f "$GO_BINARY" ]; then
    echo -e "${GREEN}✓ Go cache layer built successfully${NC}"
    echo "  Location: $GO_BINARY"
    echo "  Size: $(ls -lh $GO_BINARY | awk '{print $5}')"
else
    echo -e "${YELLOW}✗ Go build failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=================================================="
echo "✅ Build Complete!${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""
echo "📦 Binaries ready:"
echo "  1. Rust Indexer:  $RUST_BINARY"
echo "  2. Go Cache:      $GO_BINARY"
echo ""
echo "🚀 To start the stack:"
echo ""
echo "  Terminal 1:"
echo "    cd $SCRIPT_DIR/rust-indexer"
echo "    ./target/release/api-indexer"
echo ""
echo "  Terminal 2 (after Rust starts):"
echo "    cd $SCRIPT_DIR/go-cache"
echo "    ./api-cache"
echo ""
echo "🧪 Test endpoints:"
echo "  curl 'http://localhost:18791/search?keyword=test'"
echo "  curl 'http://localhost:18791/categories'"
echo "  curl 'http://localhost:18791/health'"
echo ""
echo "📊 Monitor cache:"
echo "  curl 'http://localhost:18791/cache/stats'"
echo ""
echo "📖 Full docs: $SCRIPT_DIR/HYBRID_ARCHITECTURE.md"
echo ""
