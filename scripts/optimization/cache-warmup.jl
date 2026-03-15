#!/usr/bin/env julia
using JSON, Dates

println("\n" * "="^70)
println("PHASE 5: PILLAR 1 — CACHE WARMUP")
println("="^70 * "\n")

files = [("SOUL.md", "SOUL.md"), ("IDENTITY.md", "IDENTITY.md"), ("AGENTS.md", "AGENTS.md"), ("MEMORY.md", "MEMORY.md")]
total = 0
bundle_size = 0

println("Loading context files...")
for (name, path) in files
    if isfile(path)
        c = read(path, String)
        sz = length(c)
        toks = floor(Int, length(split(c)) * 1.3)
        total += toks
        bundle_size += sz
        println("  ✓ $name: $toks tokens")
    end
end

println("\n✅ Bundle ready: $total tokens, $bundle_size chars")

warmup = Dict("timestamp" => string(now()), "total_tokens" => total, "status" => "ready")
mkpath("data/metrics")
open("data/metrics/cache-warmup-state.json", "w") do f
    write(f, JSON.json(warmup, 2))
end

println("✅ Saved warmup state\n" * "="^70 * "\n")
