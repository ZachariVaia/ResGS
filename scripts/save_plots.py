import os
import argparse
import matplotlib.pyplot as plt
import numpy as np

def generate_plots(main_folder):
    # Traverse all subfolders
    for root, dirs, files in os.walk(main_folder):
        print("CHECK:", root)
        if "plots" in root:
            split_path = os.path.join(root, "split_count.txt")

            # Only proceed if split_count exists
            if os.path.exists(split_path):
                print(f"Processing: {root}")

                split_count = np.loadtxt(split_path)

                # Create a figure
                fig, ax = plt.subplots(figsize=(12, 8))

                # Plot split count
                ax.plot(
                    range(len(split_count)),
                    split_count,
                    label='Split Count',
                    color='green'
                )

                ax.set_xlabel('Densification Iteration (*100)')
                ax.set_ylabel('Split Count (K)')
                ax.set_title('Gaussian Split Count Over Time')
                ax.legend(loc='upper left')

                # Save figure
                save_path = os.path.join(root, "plot_split.png")
                plt.tight_layout()
                plt.savefig(save_path, dpi=300)
                plt.close()

                print(f"Saved plot to {save_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate split-only plots.")
    parser.add_argument("path", type=str, help="Path to main output folder")
    args = parser.parse_args()

    generate_plots(args.path)
