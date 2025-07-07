#!/usr/bin/env bash
set -euo pipefail

MODEL=./../../models/llama-2-7b.Q4_K_M.gguf
BENCH=./../../build/bin/llama-bench
OUT_CSV=../data/bench_resultsbm.csv

# Clear and initialize the CSV file
> "$OUT_CSV"
echo "Thread Count,Gen Time (s),Tokens Generated,Tokens/sec" >> "$OUT_CSV"

# Measure model-load time once via a 0-token dummy run
START_LOAD=$(date +%s.%N)
$BENCH -m "$MODEL" -n 0
END_LOAD=$(date +%s.%N)
LOAD_TIME=$(awk -v e="$END_LOAD" -v s="$START_LOAD" 'BEGIN{printf "%.6f", e - s}')

for THREAD_COUNT in {30,32}; do
  echo "Running benchmark for $THREAD_COUNT threads..."

  START_GEN=$(date +%s.%N)
  $BENCH -m "$MODEL" -t "$THREAD_COUNT" -n 128 -b 512 -p 1024 
  END_GEN=$(date +%s.%N)

  GEN_TIME=$(awk -v e="$END_GEN" -v s="$START_GEN" 'BEGIN{printf "%.6f", e - s}')
  TOKENS_GENERATED=512
  TOKS_PER_SEC=$(awk -v tok="$TOKENS_GENERATED" -v t="$GEN_TIME" 'BEGIN{ if(t>0) printf "%.2f", tok/t; else print "0.00"}')

  echo "Thread Count: $THREAD_COUNT | Gen Time: ${GEN_TIME}s | Tokens: $TOKENS_GENERATED | Speed: ${TOKS_PER_SEC} tok/s"
  echo "$THREAD_COUNT,$GEN_TIME,$TOKENS_GENERATED,$TOKS_PER_SEC" >> "$OUT_CSV"
done

echo "Benchmarks written to $OUT_CSV"
