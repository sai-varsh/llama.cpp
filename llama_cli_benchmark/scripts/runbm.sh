#!/usr/bin/env bash
set -euo pipefail

MODEL=./../../models/llama-2-7b.Q4_K_M.gguf
CLI=./../../build/bin/llama-cli
OUT_CSV=../data/resultsbm.csv
> "$OUT_CSV"
echo -e "Thread Count,Gen Time (s),Tokens Generated,Tokens/sec(Weighted mean)\n" >> "$OUT_CSV"

# Measure model-load time once via a 0-token dummy run
START_LOAD=$(date +%s.%N)
$CLI -m "$MODEL" -n 0 --seed 0 >/dev/null
END_LOAD=$(date +%s.%N)
LOAD_TIME=$(awk -v e="$END_LOAD" -v s="$START_LOAD" 'BEGIN{printf "%.6f", e - s}')

for THREAD_COUNT in {1..64}; do
  echo "Running benchmark for $THREAD_COUNT threads..."
  TOTAL_GEN_TIME=0
  TOTAL_TOKENS=0
  WEIGHTED_SUM=0

  for PROMPT in \
    "Here is a detailed explanation on machine learning algorithms, which covers supervised learning, unsupervised learning, neural networks and also the real-world applications for each type. Machine learning began " \
    "Here is a comprehensive essay on the history and future of space exploration, discussing major milestones like the Apollo missions, the International Space Station, Mars rovers, and the role of private companies in space travel. Space exploration has always" \
    "This essay examines existential philosophy, focusing on thinkers like Kierkegaard, Nietzsche, and Sartre, and their views on meaning, freedom, and authenticity. Existentialism is a philosophical " \
  ; do
    PROMPT_TOKENS=$(echo "$PROMPT" | wc -w)
    START_GEN=$(date +%s.%N)
    OUTPUT_FILE=$(mktemp)
    $CLI \
      -m "$MODEL" \
      -t "$THREAD_COUNT" \
      -n 512 \
      -p "$PROMPT" \
      --simple-io | tee "$OUTPUT_FILE"
    OUTPUT=$(cat "$OUTPUT_FILE")
    rm "$OUTPUT_FILE"
    END_GEN=$(date +%s.%N)
    GEN_TIME=$(awk -v e="$END_GEN" -v s="$START_GEN" 'BEGIN{printf "%.6f", e - s}')
    GENERATED_TOKENS=$(echo "$OUTPUT" | wc -w)
    TOKENS=$(( GENERATED_TOKENS - PROMPT_TOKENS ))
    (( TOKENS < 0 )) && TOKENS=0
    TOKS_PER_SEC=$(awk -v tok="$TOKENS" -v t="$GEN_TIME" 'BEGIN{ if(t>0) printf "%.6f", tok/t; else print "0.00"}')
    TOTAL_GEN_TIME=$(awk -v a="$TOTAL_GEN_TIME" -v b="$GEN_TIME" 'BEGIN{printf "%.6f", a + b}')
    echo "$TOKENS,$GEN_TIME,$TOKS_PER_SEC" >> "$OUT_CSV"
    TOTAL_TOKENS=$(( TOTAL_TOKENS + TOKENS ))
    WEIGHTED_SUM=$(awk -v ws="$WEIGHTED_SUM" -v c="$TOKENS" -v p="$TOKS_PER_SEC" 'BEGIN{printf "%.6f", ws + (c * p)}')
  done

  WEIGHTED_MEAN=$(awk -v ws="$WEIGHTED_SUM" -v total="$TOTAL_TOKENS" 'BEGIN{ if(total>0) printf "%.2f", ws / total; else print "0.00"}')
  echo -e "\n$THREAD_COUNT,$TOTAL_GEN_TIME,$TOTAL_TOKENS,$WEIGHTED_MEAN \n\n\n" >> "$OUT_CSV"
done

echo "Benchmarks written to $OUT_CSV"
