#!/usr/bin/env bash
set -euo pipefail

MODEL=./../../models/llama-2-7b.Q4_K_M.gguf
BENCH=./../../build/bin/llama-bench
OUT_CSV=../data/res.csv

THREADS_LIST=(32 64 90 95 96 100 140 190 191 192)
BATCH_LIST=(2 4 8 16)

# Header for CSV
echo "threadcount,batchsize,prompt_processing_tok_per_sec,generation_tok_per_sec" > "$OUT_CSV"

for threads in "${THREADS_LIST[@]}"; do
  for batch in "${BATCH_LIST[@]}"; do
    # Prompt processing (n_prompt=512, n_gen=0)
    prompt_json="bench_${threads}t_b${batch}_prompt.json"
    taskset -c 0-$(($threads-1)) "$BENCH" \
      -m "$MODEL" \
      -t "$threads" \
      -n 0 \
      -p 512 \
      -b "$batch" \
      -o json > "$prompt_json"
    prompt_avg_ts=$(jq '.[0].avg_ts' "$prompt_json")

    # Generation (n_prompt=0, n_gen=128)
    gen_json="bench_${threads}t_b${batch}_gen.json"
    taskset -c 0-$(($threads-1)) "$BENCH" \
      -m "$MODEL" \
      -t "$threads" \
      -n 128 \
      -p 0 \
      -b "$batch" \
      -o json > "$gen_json"
    gen_avg_ts=$(jq '.[0].avg_ts' "$gen_json")

    # Calculate tokens/sec (tok/sec = 1000 / avg_ts in ms)
    prompt_tok_per_sec=$(awk -v ts="$prompt_avg_ts" 'BEGIN {if(ts>0) printf "%.2f", 1000/ts; else print "0.00"}')
    gen_tok_per_sec=$(awk -v ts="$gen_avg_ts" 'BEGIN {if(ts>0) printf "%.2f", 1000/ts; else print "0.00"}')

    echo "$threads,$batch,$prompt_tok_per_sec,$gen_tok_per_sec" >> "$OUT_CSV"
  done
done

echo "Results written to $OUT_CSV"


# #!/usr/bin/env bash
# set -euo pipefail

# MODEL=./../../models/llama-2-7b.Q4_K_M.gguf
# BENCH=./../../build/bin/llama-bench
# OUT_CSV=../data/bench_resultsbm.csv

# # Test different batch sizes
# for batch in 1 2 4 8 16 32; do
#     echo "=== Testing with batch size $batch ==="
   
#     for threads in 63; do
#         echo "Testing with $threads threads, batch $batch"
#         taskset -c 0-$(($threads-1)) ./../../build/bin/llama-bench \
#             -m ./../../models/llama-2-7b.Q4_K_M.gguf \
#             -t $threads \
#             -n 128 \
#             -p 512 \
#             -b $batch \
#             -o json > bench_${threads}t_b${batch}.json
#     done
# done