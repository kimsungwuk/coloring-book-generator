import os
import time
import json
import datetime
import sys
import random
import cv2
import numpy as np
from google import genai
from google.genai import types
from dotenv import load_dotenv

# .env 파일에서 환경 변수 로드
load_dotenv()

# Gemini 설정
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

# 새로운 SDK 클라이언트 초기화
client = genai.Client(api_key=GEMINI_API_KEY)

def load_config():
    config_path = 'assets/data/coloring_pages.json'
    if os.path.exists(config_path):
        with open(config_path, 'r', encoding='utf-8') as f:
            try:
                return json.load(f)
            except json.JSONDecodeError:
                pass
    return {"categories": [], "pages": []}

def save_config(config):
    config_path = 'assets/data/coloring_pages.json'
    with open(config_path, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)

def apply_bw_postprocess(image_path: str, threshold_value: int = 200):
    """
    이미지를 흑백(이진화)으로 변환합니다.
    - 회색 톤 제거 및 선명한 선 확보
    - 배경 반전 보정
    """
    try:
        # 이미지 로드
        img = cv2.imread(image_path)
        if img is None:
            print(f"  경고: 이미지를 불러올 수 없습니다: {image_path}")
            return False
        
        # 그레이스케일 변환
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # 이진화 (임계값 기반)
        _, binary = cv2.threshold(gray, threshold_value, 255, cv2.THRESH_BINARY)
        
        # 배경 반전 확인 및 보정
        # 코너 픽셀들을 확인하여 배경이 검은색이면 반전
        h, w = binary.shape
        corners = [binary[0, 0], binary[0, -1], binary[-1, 0], binary[-1, -1]]
        if np.mean(corners) < 128:
            binary = cv2.bitwise_not(binary)
            
        # 가벼운 노이즈 제거만 수행
        kernel = np.ones((2, 2), np.uint8)
        binary = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel)
        
        # 저장 (원본 덮어쓰기)
        cv2.imwrite(image_path, binary)
        print(f"  ✓ 기본 흑백 변환 완료")
        return True
        
    except Exception as e:
        print(f"  경고: 후처리 실패 - {e}")
        return False
def generate_subjects(category_id, count):
    """
    Gemini를 사용하여 주어진 카테고리에 적합한 색칠공부 주제 목록을 생성합니다.
    """
    category_instruction = ""
    if category_id == "forest":
        category_instruction = (
            "The subjects must be charming scenes of forest animals doing cute activities (e.g., 'a cute squirrel having a party with acorns', 'a sleepy bear cub hugging a wooden pillow'). "
            "Focus on specific forest animals like squirrels, foxes, owls, raccoons, deer, and bears. "
        )
    elif category_id == "ocean":
        category_instruction = "The subjects must be whimsical scenes of sea creatures like 'an octopus playing a drum set' or 'a sea turtle wearing a crown made of shells'. "
    
    prompt = (
        f"Create a list of {count} unique, charming and detailed descriptions for a children's coloring book centered on the '{category_id}' category. "
        f"{category_instruction} "
        "Keep each description under 15 words. Focus on a single main subject in a simple action/setting. "
        "Return ONLY the list of descriptions separated by commas, with no numbering or extra text."
    )
    
    # 시스템 리스트 기반 모델 후보
    models_to_try = [
        'gemini-flash-latest', 
        'gemini-2.0-flash', 
        'gemini-pro-latest'
    ]
    
    for model_name in models_to_try:
        try:
            print(f"주제 생성 시도 중 (모델: {model_name})...")
            response = client.models.generate_content(
                model=model_name,
                contents=prompt
            )
            subjects = [s.strip() for s in response.text.split(',') if s.strip()]
            if subjects:
                return subjects[:count]
        except Exception as e:
            print(f"모델 {model_name} 실패: {e}")
            continue
            
    # 최종 폴백
    return [f"{category_id} subject {i+1}" for i in range(count)]

# 스타일 설정
style_prompts = {
    "cartoon": "cute cartoon style, bold thick outlines, very clean lines",
    "realistic": "detailed line art, realistic proportions, fine outlines",
    "mandala": "intricate mandala patterns, symmetrical, highly detailed geometric lines",
    "simple": "extremely simple shapes, very thick borders, minimal detail, perfect for young children"
}

def generate_coloring_pages(category_id, style, count, output_dir="assets/images"):
    """
    주어진 카테고리에 대해 이미지를 생성하고 설정 파일을 업데이트합니다.
    """
    if style not in style_prompts:
        print(f"경고: 정의되지 않은 스타일 '{style}'입니다. 'cartoon' 스타일을 기본값으로 사용합니다.")
        style = "cartoon"

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    config = load_config()
    
    # 카테고리 존재 확인
    category_exists = any(c['id'] == category_id for c in config['categories'])
    if not category_exists:
        print(f"경고: 카테고리 '{category_id}'가 JSON에 없습니다. 기본 카테고리로 추가합니다.")
        config['categories'].append({
            "id": category_id,
            "nameKey": f"category{category_id.capitalize()}"
        })

    # 주제 생성
    print(f"'{category_id}' 카테고리에 대한 {count}개의 주제를 선정 중...")
    subjects = generate_subjects(category_id, count)
    print(f"선정된 주제: {', '.join(subjects)}")

    # 시스템 리스트 기반 이미지 모델 후보
    image_models = [
        'imagen-4.0-generate-001',
        'imagen-4.0-fast-generate-001'
    ]

    for subject in subjects:
        try:
            timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
            filename = f"{category_id}_{timestamp}.png"
            output_path = os.path.join(output_dir, filename)
            
            print(f"[{subject}] 이미지 생성 시도 중 ({filename})...")
            
            # 최종 프롬프트 구성 (글자 배제 강화)
            final_prompt = (
                f"A coloring book page of a single {subject}. "
                f"Style: {style_prompts[style]}. "
                "Requirements: Single main subject centered in the frame, strictly black and white line art, pure white background, no shading, no gray tones, no colors, high contrast, clean white space for coloring. "
                "CRITICAL: ABSOLUTELY NO TEXT, NO LETTERS, NO WORDS, NO NUMBERS, NO SYMBOLS, NO LABELS, NO CAPTIONS, NO WATERMARKS, NO SIGNATURES. "
                "The image must be 100% DRAWING ONLY. DO NOT INCLUDE ANY ALPHABETIC OR NUMERIC CHARACTERS AT ALL."
            )

            success = False
            for img_model in image_models:
                try:
                    print(f"  사용 모델: {img_model}")
                    image_response = client.models.generate_images(
                        model=img_model, 
                        prompt=final_prompt,
                        config=types.GenerateImagesConfig(
                            number_of_images=1,
                            aspect_ratio="3:4",
                            output_mime_type="image/png"
                        )
                    )

                    if image_response.generated_images:
                        # 이미지 저장
                        image_response.generated_images[0].image.save(output_path)
                        
                        # 흑백 후처리 적용
                        print(f"  흑백 후처리 적용 중...")
                        apply_bw_postprocess(output_path)
                        
                        success = True
                        break
                except Exception as img_e:
                    print(f"  모델 {img_model} 실패: {img_e}")
                    continue

            if success:
                # JSON 업데이트
                page_id = f"{category_id}_{timestamp}"
                new_page = {
                    "id": page_id,
                    "name": subject,
                    "nameKey": f"page{subject.replace(' ', '')}",
                    "imagePath": f"assets/images/{filename}",
                    "categoryId": category_id
                }
                config['pages'].append(new_page)
                print(f"저장 및 등록 완료: {subject}")
            else:
                print(f"이미지 생성 실패 ({subject}): 모든 모델 시도 실패")

            # Quota 및 Timestamp 중복 방지
            time.sleep(5.0)

        except Exception as e:
            print(f"에러 발생 ({subject}): {e}")

    save_config(config)
    print("\n설정 파일(coloring_pages.json) 업데이트가 완료되었습니다.")

if __name__ == "__main__":
    print("=== Gemini 도안 대량 생성 프로그램 (V2.6) ===")
    
    if not os.getenv("GEMINI_API_KEY"):
        print("오류: .env 파일 또는 환경 변수에 GEMINI_API_KEY를 입력해주세요.")
    else:
        # 명령줄 인자 처리
        if len(sys.argv) > 1:
            category = sys.argv[1]
            if category == "random":
                config = load_config()
                if config["categories"]:
                    category = random.choice(config["categories"])["id"]
                    print(f"랜덤 카테고리 선택됨: {category}")
                else:
                    category = "animals"
            
            style = sys.argv[2] if len(sys.argv) > 2 else "cartoon"
            
            try:
                count = int(sys.argv[3]) if len(sys.argv) > 3 else 1
            except ValueError:
                count = 1
        else:
            category = input("생성할 카테고리 ID를 입력하세요 (예: animals, nature, fantasy, random): ").strip()
            if not category:
                category = "animals"
            
            if category == "random":
                config = load_config()
                if config["categories"]:
                    category = random.choice(config["categories"])["id"]
                    print(f"랜덤 카테고리 선택됨: {category}")
                else:
                    category = "animals"

            print(f"선택 가능한 스타일: {', '.join(style_prompts.keys())}")
            style = input("생성할 스타일에 입력하세요 (기본 cartoon): ").strip()
            if not style:
                style = "cartoon"
            
            try:
                count_str = input("생성할 이미지 개수를 입력하세요 (기본 1): ").strip()
                count = int(count_str) if count_str else 1
            except ValueError:
                count = 1
        
        print(f"\n'{category}' 카테고리, '{style}' 스타일로 {count}개의 이미지 자동 생성을 시작합니다.")
        generate_coloring_pages(category, style, count)
        
        print("\n모든 작업이 완료되었습니다.")
