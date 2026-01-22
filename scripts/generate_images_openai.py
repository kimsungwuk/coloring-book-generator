import os
import time
import json
import datetime
import requests
import sys
from openai import OpenAI
from dotenv import load_dotenv
from PIL import Image
from io import BytesIO

# .env 파일에서 환경 변수 로드
load_dotenv()

# OpenAI 설정
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
client = OpenAI(api_key=OPENAI_API_KEY)

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

def generate_subjects(category_id, count):
    """
    GPT를 사용하여 주어진 카테고리에 적합한 색칠공부 주제 목록을 생성합니다.
    """
    try:
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a helpful assistant that generates coloring book subjects."},
                {"role": "user", "content": f"Create a list of {count} unique and popular subjects for a children's coloring book in the '{category_id}' category. Return ONLY the names of the subjects separated by commas, no numbers or descriptions."}
            ]
        )
        text = response.choices[0].message.content
        subjects = [s.strip() for s in text.split(',') if s.strip()]
        return subjects[:count]
    except Exception as e:
        print(f"주제 생성 중 에러 발생: {e}")
        return [f"{category_id} subject {i+1}" for i in range(count)]

def generate_coloring_pages(category_id, count, output_dir="assets/images"):
    """
    OpenAI DALL-E를 사용하여 이미지를 생성하고 설정 파일을 업데이트합니다.
    """
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

    # 주제 선정
    print(f"'{category_id}' 카테고리에 대한 {count}개의 주제를 선정 중...")
    subjects = generate_subjects(category_id, count)
    print(f"선정된 주제: {', '.join(subjects)}")

    # 컬러링 도안을 위한 스타일 프롬프트 (얇고 세련된 선)
    STYLE = (
        "elegant black and white line art illustration for coloring book, "
        "fine thin clean lines, delicate outlines, detailed yet easy to color, "
        "pure white background, no shading, no gradients, no fill, "
        "high quality illustration, professional coloring page, portrait 3:4 aspect ratio"
    )

    for subject in subjects:
        try:
            timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
            filename = f"{category_id}_{timestamp}.png"
            output_path = os.path.join(output_dir, filename)
            
            print(f"[{subject}] 이미지 생성 시도 중 (DALL-E)...")
            
            # DALL-E 3를 이용한 이미지 생성 (세로형으로 생성 후 후처리 크롭)
            response = client.images.generate(
                model="dall-e-3",
                prompt=f"{subject}, {STYLE}",
                size="1024x1792",  # DALL-E 3 세로형 기본
                quality="hd",
                style="natural",
                n=1
            )

            image_url = response.data[0].url
            
            # 이미지 다운로드
            img_response = requests.get(image_url)
            img_data = img_response.content
            
            # 3:4 비율로 크롭 (1024x1792 -> 1024x1365)
            img = Image.open(BytesIO(img_data))
            width, height = img.size
            
            target_width = width
            target_height = int(width * (4 / 3)) # 3:4 비율 (너비가 3, 높이가 4)
            
            if height > target_height:
                top = (height - target_height) // 2
                bottom = top + target_height
                img = img.crop((0, top, target_width, bottom))
            
            # 저장
            img.save(output_path, "PNG")

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
            
            print(f"저장 및 등록 완료: {subject} ({filename})")
            
            # Rate Limit 방지
            time.sleep(2)

        except Exception as e:
            print(f"이미지 생성 중 에러 발생 ({subject}): {e}")

    save_config(config)
    print("\n설정 파일(coloring_pages.json) 업데이트가 완료되었습니다.")

if __name__ == "__main__":
    print("=== OpenAI(DALL-E) 도안 대량 생성 프로그램 ===")
    
    if os.getenv("OPENAI_API_KEY") == "your_openai_api_key_here" or not os.getenv("OPENAI_API_KEY"):
        print("오류: .env 파일 또는 환경 변수에 유효한 OPENAI_API_KEY를 입력해주세요.")
    else:
        # 명령줄 인자가 있으면 사용 (CI용), 없으면 입력 받음 (로컬용)
        if len(sys.argv) > 1:
            category = sys.argv[1]
            try:
                count = int(sys.argv[2]) if len(sys.argv) > 2 else 1
            except ValueError:
                count = 1
        else:
            category = input("생성할 카테고리 ID를 입력하세요 (예: animals, nature, fantasy, vehicles): ").strip()
            if not category:
                category = "animals"
            try:
                count_str = input("생성할 이미지 개수를 입력하세요 (기본 1): ").strip()
                count = int(count_str) if count_str else 1
            except ValueError:
                count = 1
        
        print(f"\n'{category}' 카테고리로 {count}개의 이미지 자동 생성을 시작합니다.")
        generate_coloring_pages(category, count)
        
        print("\n모든 작업이 완료되었습니다.")
