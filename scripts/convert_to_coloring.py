#!/usr/bin/env python3
"""
이미지를 컬러링북 도안 스타일로 변환하는 Python 스크립트

사용법:
    python convert_to_coloring.py

필요한 패키지 설치:
    pip install opencv-python numpy pillow

설명:
    assets/raw_image 폴더의 이미지를 컬러링북 도안 스타일로 변환하여
    assets/images 폴더에 저장합니다.
"""

import os
import sys
from pathlib import Path

try:
    import cv2
    import numpy as np
    from PIL import Image
except ImportError as e:
    print(f"필요한 패키지가 설치되지 않았습니다: {e}")
    print("다음 명령어로 설치해주세요:")
    print("  pip install opencv-python numpy pillow")
    sys.exit(1)


def convert_to_coloring_book(image_path: str, output_path: str, 
                              line_thickness: int = 2,
                              blur_strength: int = 5,
                              edge_low: int = 30,
                              edge_high: int = 100,
                              invert: bool = True) -> bool:
    """
    이미지를 컬러링북 도안 스타일로 변환합니다.
    
    Args:
        image_path: 입력 이미지 경로
        output_path: 출력 이미지 경로
        line_thickness: 선 두께 (1-5, 기본값 2)
        blur_strength: 블러 강도 (노이즈 제거용, 홀수만 가능, 기본값 5)
        edge_low: Canny 에지 검출 하한 임계값 (기본값 30)
        edge_high: Canny 에지 검출 상한 임계값 (기본값 100)
        invert: 반전 여부 (True: 흰 배경에 검은 선, 기본값 True)
    
    Returns:
        성공 여부
    """
    try:
        # 이미지 읽기
        img = cv2.imread(image_path)
        if img is None:
            print(f"  ❌ 이미지를 읽을 수 없습니다: {image_path}")
            return False
        
        # 그레이스케일 변환
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # 노이즈 제거를 위한 가우시안 블러
        if blur_strength % 2 == 0:
            blur_strength += 1
        blurred = cv2.GaussianBlur(gray, (blur_strength, blur_strength), 0)
        
        # Canny 에지 검출
        edges = cv2.Canny(blurred, edge_low, edge_high)
        
        # 선 두께 조절 (모폴로지 연산)
        if line_thickness > 1:
            kernel = np.ones((line_thickness, line_thickness), np.uint8)
            edges = cv2.dilate(edges, kernel, iterations=1)
        
        # 반전 (흰 배경에 검은 선)
        if invert:
            edges = cv2.bitwise_not(edges)
        
        # 저장
        cv2.imwrite(output_path, edges)
        return True
        
    except Exception as e:
        print(f"  ❌ 변환 중 오류 발생: {e}")
        return False


def convert_to_coloring_book_advanced(image_path: str, output_path: str) -> bool:
    """
    고급 방식: 적응형 임계값과 윤곽선 추출을 사용한 변환
    더 깨끗하고 부드러운 도안을 생성합니다.
    
    Args:
        image_path: 입력 이미지 경로
        output_path: 출력 이미지 경로
    
    Returns:
        성공 여부
    """
    try:
        # 이미지 읽기
        img = cv2.imread(image_path)
        if img is None:
            print(f"  ❌ 이미지를 읽을 수 없습니다: {image_path}")
            return False
        
        # 그레이스케일 변환
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # 양방향 필터로 노이즈 제거 (에지는 보존)
        filtered = cv2.bilateralFilter(gray, 9, 75, 75)
        
        # 적응형 임계값 적용
        adaptive_thresh = cv2.adaptiveThreshold(
            filtered, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY,
            blockSize=11,
            C=2
        )
        
        # 작은 노이즈 제거
        kernel = np.ones((2, 2), np.uint8)
        cleaned = cv2.morphologyEx(adaptive_thresh, cv2.MORPH_CLOSE, kernel)
        cleaned = cv2.morphologyEx(cleaned, cv2.MORPH_OPEN, kernel)
        
        # 저장
        cv2.imwrite(output_path, cleaned)
        return True
        
    except Exception as e:
        print(f"  ❌ 변환 중 오류 발생: {e}")
        return False


def convert_to_coloring_book_sketch(image_path: str, output_path: str) -> bool:
    """
    스케치 스타일 변환: 연필 스케치 느낌의 도안 생성
    
    Args:
        image_path: 입력 이미지 경로
        output_path: 출력 이미지 경로
    
    Returns:
        성공 여부
    """
    try:
        # 이미지 읽기
        img = cv2.imread(image_path)
        if img is None:
            print(f"  ❌ 이미지를 읽을 수 없습니다: {image_path}")
            return False
        
        # 그레이스케일 변환
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # 반전
        inverted = cv2.bitwise_not(gray)
        
        # 가우시안 블러
        blurred = cv2.GaussianBlur(inverted, (21, 21), 0)
        
        # 블렌딩으로 스케치 효과 생성
        sketch = cv2.divide(gray, cv2.bitwise_not(blurred), scale=256.0)
        
        # 대비 향상
        sketch = cv2.convertScaleAbs(sketch, alpha=1.2, beta=10)
        
        # 이진화로 깨끗한 선 추출
        _, binary_sketch = cv2.threshold(sketch, 240, 255, cv2.THRESH_BINARY)
        
        # 저장
        cv2.imwrite(output_path, binary_sketch)
        return True
        
    except Exception as e:
        print(f"  ❌ 변환 중 오류 발생: {e}")
        return False


def main():
    # 프로젝트 루트 경로 설정
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    
    raw_image_dir = project_root / "assets" / "raw_image"
    output_dir = project_root / "assets" / "images"
    
    # 디렉토리 확인 및 생성
    if not raw_image_dir.exists():
        print(f"❌ 원본 이미지 폴더가 없습니다: {raw_image_dir}")
        print("assets/raw_image 폴더를 생성하고 변환할 이미지를 넣어주세요.")
        sys.exit(1)
    
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # 지원 이미지 확장자
    supported_extensions = {'.png', '.jpg', '.jpeg', '.bmp', '.webp', '.tiff'}
    
    # 이미지 파일 목록 가져오기
    image_files = [
        f for f in raw_image_dir.iterdir()
        if f.is_file() and f.suffix.lower() in supported_extensions
    ]
    
    if not image_files:
        print(f"❌ 변환할 이미지가 없습니다.")
        print(f"   {raw_image_dir} 폴더에 이미지 파일을 넣어주세요.")
        sys.exit(1)
    
    print("=" * 60)
    print("🎨 컬러링북 도안 변환기")
    print("=" * 60)
    print(f"📂 입력 폴더: {raw_image_dir}")
    print(f"📂 출력 폴더: {output_dir}")
    print(f"📷 발견된 이미지: {len(image_files)}개")
    print("-" * 60)
    
    # 변환 방식 선택
    print("\n변환 방식을 선택하세요:")
    print("  1. 기본 (Canny 에지 검출) - 깔끔한 선")
    print("  2. 고급 (적응형 임계값) - 디테일 보존")
    print("  3. 스케치 (연필 스케치 스타일)")
    print("  4. 모든 방식으로 변환 (비교용)")
    
    try:
        choice = input("\n선택 (1-4, 기본값 1): ").strip() or "1"
    except EOFError:
        choice = "1"
    
    if choice not in ["1", "2", "3", "4"]:
        choice = "1"
    
    print("-" * 60)
    
    success_count = 0
    fail_count = 0
    
    for i, image_file in enumerate(image_files, 1):
        print(f"\n[{i}/{len(image_files)}] 처리 중: {image_file.name}")
        
        input_path = str(image_file)
        base_name = image_file.stem
        
        if choice == "4":
            # 모든 방식으로 변환
            methods = [
                ("basic", convert_to_coloring_book),
                ("advanced", convert_to_coloring_book_advanced),
                ("sketch", convert_to_coloring_book_sketch),
            ]
            
            for method_name, method_func in methods:
                output_filename = f"{base_name}_{method_name}.png"
                output_path = str(output_dir / output_filename)
                
                if method_name == "basic":
                    result = method_func(input_path, output_path)
                else:
                    result = method_func(input_path, output_path)
                
                if result:
                    print(f"  ✅ {method_name}: {output_filename}")
                    success_count += 1
                else:
                    fail_count += 1
        else:
            # 선택된 방식으로 변환
            output_filename = f"{base_name}_coloring.png"
            output_path = str(output_dir / output_filename)
            
            if choice == "1":
                result = convert_to_coloring_book(input_path, output_path)
            elif choice == "2":
                result = convert_to_coloring_book_advanced(input_path, output_path)
            else:  # choice == "3"
                result = convert_to_coloring_book_sketch(input_path, output_path)
            
            if result:
                print(f"  ✅ 저장됨: {output_filename}")
                success_count += 1
            else:
                fail_count += 1
    
    print("\n" + "=" * 60)
    print("📊 변환 완료!")
    print(f"   ✅ 성공: {success_count}개")
    print(f"   ❌ 실패: {fail_count}개")
    print(f"   📂 출력 폴더: {output_dir}")
    print("=" * 60)


if __name__ == "__main__":
    main()
