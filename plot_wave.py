import matplotlib.pyplot as plt
import pandas as pd
import sys


try:

    df = pd.read_csv("wave_debug.csv")
    df.columns = df.columns.str.strip().str.lower()
except FileNotFoundError:
    print("Error: wave_debug.csv not found. Run 'fpm run' first!")
    sys.exit(1)




plt.figure(figsize=(10, 6))
plt.plot(df.iloc[:, 0], df.iloc[:, 1], marker='o', markersize=2, linestyle='-', color='#007acc')



plt.title("Waveform Inspection (First 500 Samples)")
plt.xlabel("Time (seconds)")
plt.ylabel("Amplitude (-1.0 to 1.0)")
plt.grid(True, alpha=0.3)
plt.axhline(0, color='black', linewidth=0.8) # Zero line


plt.savefig("waveform_plot.png")
print("Plot saved to waveform_plot.png")
plt.show()