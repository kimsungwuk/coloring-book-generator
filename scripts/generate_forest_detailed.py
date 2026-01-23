import os
import time
import json
import datetime
import random
from google import genai
from google.genai import types
from dotenv import load_dotenv

load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
client = genai.Client(api_key=GEMINI_API_KEY)

def load_config():
    config_path = 'assets/data/coloring_pages.json'
    with open(config_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_config(config):
    config_path = 'assets/data/coloring_pages.json'
    with open(config_path, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)

def generate_forest_collection():
    subjects = [
        "A cute squirrel wearing a party hat in front of a small acorn cake",
        "A wise owl wearing large glasses reading a thick book on a tree branch",
        "An artist fox holding a palette and brush painting a forest landscape",
        "A baby frog holding a large lotus leaf as an umbrella in the rain",
        "A baby bear cub sleeping soundly on a mossy bed with a small pillow",
        "A raccoon chef stirring a pot of berry soup over a campfire",
        "An otter sitting by a stream holding a small wooden fishing rod",
        "A musician cricket playing a tiny violin under a large mushroom",
        "A graceful deer carrying a basket of colorful forest flowers",
        "A hedgehog roasting a marshmallow on a stick in front of a tiny tent",
        "A happy rabbit swinging on a vine swing hanging from a large oak tree",
        "A mole writing a letter with a quill pen next to a woodland mailbox",
        "A badger relaxing in a small hammock tied between two birch trees",
        "A young wolf pup wearing an explorer hat holding a map and compass",
        "A baby lynx sitting on a log blowing giant soap bubbles",
        "A weasel wearing a scarf skating gracefully on a frozen forest pond",
        "A friendly wild boar carrying a beautifully wrapped gift box",
        "A squirrel photographer holding a tiny vintage camera taking flower photos",
        "A busy raccoon washing a small handkerchief in a clear forest brook",
        "A skunk astronomer looking through a telescope at a starry night sky"
    ]
    
    style_prompt = "cute cartoon style, bold thick outlines, very clean lines, simple shapes"
    category_id = "forest"
    output_dir = "assets/images"
    
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    config = load_config()
    # Ensure category exists
    if not any(c['id'] == category_id for c in config['categories']):
        config['categories'].append({"id": category_id, "nameKey": "categoryForest", "isFree": True})

    image_models = ['imagen-4.0-generate-001', 'imagen-4.0-fast-generate-001']

    for i, subject in enumerate(subjects):
        try:
            timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
            filename = f"forest_{timestamp}_{i}.png"
            output_path = os.path.join(output_dir, filename)
            
            final_prompt = (
                f"A coloring book page of {subject}. "
                f"Style: {style_prompt}. "
                "Requirements: Single main subject centered, strictly black and white line art, pure white background, no shading, no gray tones, no colors, high contrast, clean white space. "
                "CRITICAL: NO TEXT, NO LETTERS, NO WORDS, NO NUMBERS, NO SYMBOLS, NO WATERMARKS, NO SIGNATURES."
            )
            
            print(f"[{i+1}/20] Generating: {subject}")
            
            success = False
            for model in image_models:
                try:
                    response = client.models.generate_images(
                        model=model,
                        prompt=final_prompt,
                        config=types.GenerateImagesConfig(
                            number_of_images=1,
                            aspect_ratio="3:4",
                            output_mime_type="image/png"
                        )
                    )
                    if response.generated_images:
                        response.generated_images[0].image.save(output_path)
                        success = True
                        break
                except Exception as e:
                    print(f"  Model {model} failed: {e}")
                    continue
            
            if success:
                new_page = {
                    "id": f"forest_{timestamp}_{i}",
                    "name": subject,
                    "nameKey": f"pageForest{i+1}",
                    "imagePath": f"assets/images/{filename}",
                    "categoryId": category_id
                }
                config['pages'].append(new_page)
                print(f"  Success: {filename}")
                save_config(config) # Save progress after each success
            else:
                print(f"  Failed to generate image for: {subject}")
            
            time.sleep(2) # Avoid rate limits
            
        except Exception as e:
            print(f"  Error: {e}")

    print("\nForest collection generation complete!")

if __name__ == "__main__":
    generate_forest_collection()
