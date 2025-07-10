import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv('avg_ts_results.csv')

batch_colors = {2: 'tab:blue', 4: 'tab:orange', 8: 'tab:green', 16: 'tab:red'}
batch_labels = {2: 'Batch 2', 4: 'Batch 4', 8: 'Batch 8', 16: 'Batch 16'}
thread_counts = sorted(df['thread_count'].unique())
thread_labels = [str(tc) for tc in thread_counts]

# Custom x positions: keep 95/96 and 190/191/192 slightly closer
custom_x_pos = {}
base = 0
positions = []
gap = 1.0
close_gap = 0.5
for i, tc in enumerate(thread_counts):
    if i > 0 and ((tc == 96 and thread_counts[i-1] == 95) or (tc in [191,192] and thread_counts[i-1] in [190,191])):
        base += close_gap
    else:
        base += gap
    custom_x_pos[tc] = base
    positions.append(base)
x_labels = [str(tc) for tc in thread_counts]
x_ticks = [custom_x_pos[tc] for tc in thread_counts]

# Generation only plot
gen_df = df[df['type'] == 'gen']
plt.figure(figsize=(24, 12))
for batch_size in sorted(gen_df['batch_size'].unique()):
    sub = gen_df[gen_df['batch_size'] == batch_size].sort_values('thread_count')
    if not sub.empty:
        x = [custom_x_pos[tc] for tc in sub['thread_count']]
        plt.plot(
            x, sub['avg_ts'],
            marker='o',
            color=batch_colors[batch_size],
            label=batch_labels[batch_size],
            linewidth=2.5,
            markersize=8
        )
plt.title('Generation only: Eval tokens/sec vs Thread Count by Batch Size', fontsize=20, fontweight='bold')
plt.xlabel('Thread Count', fontsize=16, fontweight='bold')
plt.ylabel('Eval tokens/sec (avg_ts)', fontsize=16, fontweight='bold')
plt.xticks(x_ticks, x_labels, rotation=0)
plt.ylim(5, 75)
plt.grid(True, linestyle='--', alpha=0.5)
plt.legend(fontsize=18)
plt.tight_layout()
plt.savefig('avg_ts_vs_thread_count_generation.png', dpi=200)
plt.close()

# Prompt processing plot
prompt_df = df[df['type'] == 'prompt']
plt.figure(figsize=(22, 10))
for batch_size in sorted(prompt_df['batch_size'].unique()):
    sub = prompt_df[prompt_df['batch_size'] == batch_size].sort_values('thread_count')
    if not sub.empty:
        x = [custom_x_pos[tc] for tc in sub['thread_count']]
        plt.plot(
            x, sub['avg_ts'],
            marker='o',
            color=batch_colors[batch_size],
            label=batch_labels[batch_size],
            linewidth=2.5,
            markersize=8
        )
plt.title('Prompt processing: Eval tokens/sec vs Thread Count by Batch Size', fontsize=20, fontweight='bold')
plt.xlabel('Thread Count', fontsize=16, fontweight='bold')
plt.ylabel('Eval tokens/sec (avg_ts)', fontsize=16, fontweight='bold')
plt.xticks(x_ticks, x_labels, rotation=0)
plt.grid(True, linestyle='--', alpha=0.5)
plt.legend(fontsize=18)
plt.tight_layout()
plt.savefig('avg_ts_vs_thread_count_prompt.png', dpi=200)
plt.close()