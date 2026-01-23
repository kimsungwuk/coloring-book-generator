import os
import datetime
import time
from google import genai
from google.genai import types
from dotenv import load_dotenv

load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
client = genai.Client(api_key=GEMINI_API_KEY)

def generate_sample():
    subject = "a cute squirrel having a party with acorns, wearing a party hat, sitting in front of a small acorn cake, smiling"
    style_prompt = "cute cartoon style, bold thick outlines, very clean lines"
    
    final_prompt = (
        f"A coloring book page of {subject}. "
        f"Style: {style_prompt}. "
        "Requirements: Single main subject centered in the frame, strictly black and white line art, pure white background, no shading, no gray tones, no colors, high contrast, clean white space for coloring. "
        "CRITICAL: ABSOLUTELY NO TEXT, NO LETTERS, NO WORDS, NO NUMBERS, NO SYMBOLS, NO LABELS, NO CAPTIONS, NO WATERMARKS, NO SIGNATURES. "
        "The image must be 100% DRAWING ONLY. DO NOT INCLUDE ANY ALPHABETIC OR NUMERIC CHARACTERS AT ALL."
    )
    
    print(f"샘플 생성 시작: {subject}")
    
    try:
        image_response = client.models.generate_images(
            model='imagen-4.0-generate-001',
            prompt=final_prompt,
            config=types.GenerateImagesConfig(
                number_of_images=1,
                aspect_ratio="3:4",
                output_mime_type="image/png"
            )
        )
        
        if image_response.generated_images:
            output_path = "assets/images/sample_squirrel.png"
            image_response.generated_images[0].image.save(output_path)
            print(f"성공! 이미지 저장됨: {output_path}")
        else:
            print("이미지 생성 실패")
    except Exception as e:
        print(f"에러 발생: {e}")

if __name__ == "__main__":
    generate_sample()
