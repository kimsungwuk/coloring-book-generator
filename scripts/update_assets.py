import os
import json

def update_coloring_pages():
    """
    assets/images 폴더의 이미지들을 스캔하여 assets/data/coloring_pages.json 파일을 갱신합니다.
    새로운 구조(categories, pages)를 유지합니다.
    """
    IMAGES_DIR = 'assets/images'
    DATA_DIR = 'assets/data'
    JSON_FILE = os.path.join(DATA_DIR, 'coloring_pages.json')
    VALID_EXTENSIONS = ('.png', '.jpg', '.jpeg', '.webp')

    # 기존 데이터 로드
    if os.path.exists(JSON_FILE):
        with open(JSON_FILE, 'r', encoding='utf-8') as f:
            try:
                data = json.load(f)
            except json.JSONDecodeError:
                data = {"categories": [], "pages": []}
    else:
        data = {"categories": [], "pages": []}

    # 기본 카테고리 보장 (데이터가 비어있을 경우)
    if not data.get("categories"):
        data["categories"] = [
            {"id": "animals", "nameKey": "categoryAnimals"},
            {"id": "nature", "nameKey": "categoryNature"},
            {"id": "fantasy", "nameKey": "categoryFantasy"},
            {"id": "vehicles", "nameKey": "categoryVehicles"}
        ]

    if not data.get("pages"):
        data["pages"] = []

    # 기존 페이지 ID 세트 생성 (중복 방지)
    existing_ids = {p['id'] for p in data['pages']}
    
    # 이미지 폴더 확인
    if not os.path.exists(IMAGES_DIR):
        print(f"오류: {IMAGES_DIR} 디렉토리를 찾을 수 없습니다.")
        return

    filenames = sorted(os.listdir(IMAGES_DIR))
    new_pages_added = 0
    
    for filename in filenames:
        if filename == 'app_icon.png' or not filename.lower().endswith(VALID_EXTENSIONS):
            continue
            
        file_id = os.path.splitext(filename)[0]
        
        # 이미 등록된 파일이면 건너뜀
        if file_id in existing_ids:
            continue
            
        # 파일명에서 카테고리 추측 (예: 'animals_2024.png' -> category: 'animals')
        category_id = 'animals' # 기본값
        for cat in data['categories']:
            if file_id.startswith(f"{cat['id']}_"):
                category_id = cat['id']
                break
        
        # 이름 생성
        name = file_id.replace('_', ' ').title()
        
        new_page = {
            "id": file_id,
            "name": name,
            "nameKey": f"page{file_id.replace('_', '').title()}",
            "imagePath": f"assets/images/{filename}",
            "categoryId": category_id
        }
        data["pages"].append(new_page)
        new_pages_added += 1

    # JSON 파일 저장
    with open(JSON_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"성공: {JSON_FILE} 파일이 업데이트되었습니다.")
    print(f"새로 추가된 도안: {new_pages_added}개 (총 {len(data['pages'])}개)")

if __name__ == "__main__":
    update_coloring_pages()
