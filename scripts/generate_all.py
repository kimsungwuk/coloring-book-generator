import os
import subprocess
import sys

# Categories to generate
categories = ["forest", "ocean", "fairy", "vehicles", "dinosaurs", "desserts"]
style = "cartoon"
count = 20

def run_gen(cat):
    print(f"\n>>> Generating {cat}...")
    subprocess.run(["python", "scripts/generate_images_gemini.py", cat, style, str(count)])

if __name__ == "__main__":
    for cat in categories:
        run_gen(cat)
    print("\nAll categories generated!")
