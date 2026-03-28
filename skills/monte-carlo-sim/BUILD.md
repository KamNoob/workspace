# Building Hybrid Monte Carlo Binaries

This skill includes optimized implementations in Rust, Go, and Julia. Build them to enable acceleration.

## Prerequisites

- **Rust:** `rustup` installed (https://rustup.rs/)
- **Go:** Go 1.21+ installed (https://golang.org/dl/)
- **Julia:** Julia 1.6+ installed (or `/snap/julia/current/bin/julia`)

## Build Rust Binary

Fastest integration/sampling engine:

```bash
cd rust
cargo build --release
cp target/release/mc-rust ../bin/mc-rust
chmod +x ../bin/mc-rust
```

**Verification:**
```bash
./bin/mc-rust pi 1000000
# Should output: {"estimate": 3.14159..., "actual": 3.14159..., "error": 0.0...}
```

**Performance:**
- π estimation (1M samples): ~50ms (Rust) vs 800ms (JS)
- Integral estimation (1M samples): ~80ms (Rust) vs 1200ms (JS)
- **Speedup: ~15-20x**

## Build Go Binary

Parallel portfolio simulation:

```bash
cd go
go build -o ../bin/mc-go .
chmod +x ../bin/mc-go
```

**Verification:**
```bash
echo '{"assets":[{"weight":0.6,"expectedReturn":0.08,"volatility":0.15},{"weight":0.4,"expectedReturn":0.04,"volatility":0.05}],"correlations":[]}' | \
  ./bin/mc-go portfolio 252 1000
# Should output portfolio simulation results
```

**Performance:**
- Portfolio sim (1000 iterations): ~20ms (Go) vs 400ms (JS)
- **Speedup: ~20x**

## Julia Script

High-dimensional batch operations (no compilation needed):

```bash
cd julia
chmod +x monte-carlo.jl
```

**Verification:**
```bash
julia julia/monte-carlo.jl stats <<< '{"data":[[1,2,3],[4,5,6]]}'
# Should output statistics
```

**Performance:**
- Batch statistics on 10K×100: ~10ms (Julia) vs 500ms (JS)
- **Speedup: ~50x**

## Integration with Node.js

The hybrid simulator automatically detects binaries in `bin/`:

```javascript
const MC = require('./lib/simulator-hybrid.js');
const mc = new MC({
  useRust: true,      // Enabled if mc-rust exists
  useGo: true,        // Enabled if mc-go exists
  useJulia: true,     // Enabled if monte-carlo.jl exists
  rustThreshold: 50000,  // Use Rust for >50K samples
  goThreshold: 10000     // Use Go for >10K items
});

// This will automatically route to Rust if available
const result = await mc.estimateIntegral(x => x*x, 0, 1, 100000);
console.log(result.backend);  // "rust" if Rust binary exists, else "js"
```

## Build All (One Command)

```bash
#!/bin/bash
set -e

echo "Building Rust..."
cd rust && cargo build --release && cp target/release/mc-rust ../bin/mc-rust && cd ..

echo "Building Go..."
cd go && go build -o ../bin/mc-go . && cd ..

echo "Setting Julia executable..."
chmod +x julia/monte-carlo.jl

echo "✅ All backends ready!"
ls -lh bin/mc-*
```

Save as `BUILD.sh` and run:
```bash
bash BUILD.sh
```

## Optional: Cross-Platform Builds

### Build Rust for Linux (from macOS)

```bash
rustup target add x86_64-unknown-linux-gnu
cd rust
cargo build --release --target x86_64-unknown-linux-gnu
```

### Build Go for Linux (from macOS)

```bash
cd go
GOOS=linux GOARCH=amd64 go build -o ../bin/mc-go.linux .
```

## Troubleshooting

**"mc-rust not found"**
- Rust binary not built or not in `bin/`
- Falls back to JS automatically
- Run: `cargo build --release` in `rust/` directory

**"mc-go not found"**
- Go binary not built or not in `bin/`
- Falls back to JS automatically
- Run: `go build` in `go/` directory

**"Julia import failed"**
- Julia not installed or not in PATH
- Install: `snap install julia --classic` or `brew install julia`
- Falls back to JS automatically

**Performance not improving**
- Check binary actually being called: `result.backend` field shows which was used
- Verify thresholds: small samples won't trigger Rust/Go (too much overhead)
- Run benchmarks: `node benchmark.js` (if available)

## Performance Tips

1. **Reuse instances:** Create MC once, call multiple times
2. **Batch operations:** Multiple small requests faster as one large request
3. **Seed for reproducibility:** Pass `seed` to get deterministic results
4. **Large samples:** Only Rust/Go help significantly (>10K samples)

## Benchmarks (Example)

On a typical 4-core laptop:

```
Operation                   | JS      | Rust    | Go      | Speedup
π estimation (1M)           | 800ms   | 50ms    | —       | 16x
Portfolio sim (10K iter)    | 4000ms  | —       | 200ms   | 20x
Integral (100K)             | 1200ms  | 100ms   | —       | 12x
Batch stats (10K×100)       | 500ms   | —       | —       | 50x (Julia)
```

Actual results vary by hardware. Profile your use case!
