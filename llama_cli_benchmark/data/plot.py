import pandas as pd
import matplotlib.pyplot as plt

# Load the filtered CSV file
df = pd.read_csv("./filtered_tokens_per_sec.csv")

# Sort by Thread Count for a clean plot
df.sort_values("Thread Count", inplace=True)

# Plotting
plt.figure(figsize=(15,7))  # Increased width for better visibility
plt.plot(df["Thread Count"], df["Eval Tokens/sec"], marker='o', linestyle='-', color='purple' , markersize=8, linewidth=2, label='Tokens/sec (Weighted Mean)')
plt.title("Inference throughtput vs Thread Count")
plt.xlabel("Thread Count")
plt.ylabel("Eval Tokens per sec")
plt.grid(True, which='both', axis='both', linestyle='--', linewidth=0.5, alpha=0.7)  # Enhanced grid

plt.xlim(1, 65) 
plt.ylim(0, 40)

plt.xticks(df["Thread Count"])  # Show every thread count on x-axis
plt.tight_layout()

# Save the plot
plt.savefig("tokens_per_sec_vs_thread_count.png")
plt.show()
