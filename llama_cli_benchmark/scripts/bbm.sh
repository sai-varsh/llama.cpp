#!/usr/bin/env bash
set -euo pipefail

MODEL=./../../models/llama-2-7b.Q4_K_M.gguf
BENCH=./../../build/bin/llama-bench
OUT_CSV=../data/bench_resultsbm.csv

THREADS_LIST=(8 16 32 60 61 62 63 64)
TOKENS=128
PROMPT=512

# Prepare output CSV
echo "threads,tokens_per_sec" > "$OUT_CSV"

for threads in "${THREADS_LIST[@]}"; do
    echo "Testing with $threads threads"
    # Run llama-bench and capture output
    output=$(taskset -c 0-$(($threads-1)) "$BENCH" \
        -m "$MODEL" \
        -t "$threads" \
        -n "$TOKENS" \
        -p "$PROMPT" 2>&1)
    # Extract tokens/sec (adjust grep/awk as needed for your llama-bench output)
    TOKS_PER_SEC=$(echo "$output" | grep -i 'tokens per second' | head -n1 | awk '{print $(NF-1)}')
    # If parsing fails, default to 0
    if [[ -z "$TOKS_PER_SEC" ]]; then
        TOKS_PER_SEC=0
    fi
    echo "$threads,$TOKS_PER_SEC" >> "$OUT_CSV"
done

echo "Benchmarks written to $OUT_CSV"