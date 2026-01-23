"""
이미지 자동 보정 스크립트 (Python + OpenCV)
- AI 생성 이미지를 완벽한 흑백 컬러링북 도안으로 변환
- 회색 톤 제거, 선명한 검정 선, 순백 배경
"""
import os
import sys
import cv2
import numpy as np
from pathlib import Path


def convert_to_pure_bw(
    image_path: str,
    output_path: str = None,
    threshold_value: int = 200,
    line_thickness_adjust: int = 0,
    denoise: bool = True,
    invert_if_needed: bool = True
) -> str:
    """
    이미지를 완벽한 흑백으로 변환합니다.
    
    Args:
        image_path: 원본 이미지 경로
        output_path: 저장할 경로 (None이면 원본 덮어쓰기)
        threshold_value: 이진화 임계값 (0-255, 높을수록 더 많은 부분이 흰색)
        line_thickness_adjust: 선 두께 조정 (-2~2, 양수면 두꺼워짐)
        denoise: 노이즈 제거 여부
        invert_if_needed: 배경이 어두우면 자동 반전
    
    Returns:
        저장된 파일 경로
    """
    # 이미지 로드
    img = cv2.imread(image_path)
    if img is None:
        raise ValueError(f"이미지를 불러올 수 없습니다: {image_path}")
    
    # 그레이스케일 변환
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # 노이즈 제거 (선택적)
    if denoise:
        gray = cv2.GaussianBlur(gray, (3, 3), 0)
    
    # 적응형 이진화 또는 단순 이진화 선택
    # 적응형: 조명이 불균일한 이미지에 좋음
    # 단순: 균일한 배경에 좋음
    
    # 먼저 단순 이진화 시도
    _, binary = cv2.threshold(gray, threshold_value, 255, cv2.THRESH_BINARY)
    
    # 배경이 어두운지 확인하고 필요시 반전
    if invert_if_needed:
        # 코너 픽셀들의 평균으로 배경색 추정
        corners = [
            binary[0, 0], binary[0, -1], 
            binary[-1, 0], binary[-1, -1]
        ]
        avg_corner = np.mean(corners)
        
        # 배경이 검정(0에 가까움)이면 반전
        if avg_corner < 128:
            binary = cv2.bitwise_not(binary)
    
    # 선 두께 조정
    if line_thickness_adjust != 0:
        kernel = np.ones((3, 3), np.uint8)
        if line_thickness_adjust > 0:
            # 침식 (선이 두꺼워짐 - 검정 영역 확장)
            binary = cv2.erode(binary, kernel, iterations=abs(line_thickness_adjust))
        else:
            # 팽창 (선이 얇아짐 - 흰색 영역 확장)
            binary = cv2.dilate(binary, kernel, iterations=abs(line_thickness_adjust))
    
    # 작은 노이즈 점 제거
    if denoise:
        # 흰색 노이즈 제거 (검정 배경의 흰 점)
        kernel_small = np.ones((2, 2), np.uint8)
        binary = cv2.morphologyEx(binary, cv2.MORPH_CLOSE, kernel_small)
        # 검정 노이즈 제거 (흰색 배경의 검정 점)
        binary = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel_small)
    
    # 저장 경로 결정
    if output_path is None:
        output_path = image_path
    
    # 저장
    cv2.imwrite(output_path, binary)
    print(f"✓ 변환 완료: {output_path}")
    
    return output_path


def process_directory(
    input_dir: str,
    output_dir: str = None,
    threshold_value: int = 200,
    extensions: tuple = ('.png', '.jpg', '.jpeg', '.webp')
):
    """
    디렉토리 내 모든 이미지를 처리합니다.
    
    Args:
        input_dir: 입력 디렉토리
        output_dir: 출력 디렉토리 (None이면 원본 위치에 '_bw' 접미사 추가)
        threshold_value: 이진화 임계값
        extensions: 처리할 파일 확장자
    """
    input_path = Path(input_dir)
    
    if output_dir:
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
    else:
        output_path = None
    
    processed = 0
    errors = 0
    
    for file in input_path.iterdir():
        if file.suffix.lower() in extensions:
            try:
                if output_path:
                    out_file = output_path / file.name
                else:
                    out_file = file  # 원본 덮어쓰기
                
                convert_to_pure_bw(
                    str(file),
                    str(out_file),
                    threshold_value=threshold_value
                )
                processed += 1
            except Exception as e:
                print(f"✗ 오류 ({file.name}): {e}")
                errors += 1
    
    print(f"\n처리 완료: {processed}개 성공, {errors}개 실패")


def interactive_threshold(image_path: str):
    """
    트랙바를 사용하여 최적의 임계값을 찾습니다.
    (GUI 환경 필요)
    """
    img = cv2.imread(image_path)
    if img is None:
        raise ValueError(f"이미지를 불러올 수 없습니다: {image_path}")
    
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    def update_threshold(val):
        _, binary = cv2.threshold(gray, val, 255, cv2.THRESH_BINARY)
        cv2.imshow('Preview', binary)
    
    cv2.namedWindow('Preview')
    cv2.createTrackbar('Threshold', 'Preview', 200, 255, update_threshold)
    
    update_threshold(200)
    
    print("트랙바로 임계값을 조정하세요. ESC 키를 누르면 종료됩니다.")
    while True:
        key = cv2.waitKey(1) & 0xFF
        if key == 27:  # ESC
            break
    
    final_threshold = cv2.getTrackbarPos('Threshold', 'Preview')
    cv2.destroyAllWindows()
    
    print(f"선택된 임계값: {final_threshold}")
    return final_threshold


if __name__ == "__main__":
    print("=== 이미지 흑백 변환 스크립트 ===\n")
    
    if len(sys.argv) < 2:
        print("사용법:")
        print("  단일 파일: python image_postprocess.py <이미지경로> [임계값]")
        print("  디렉토리:  python image_postprocess.py <디렉토리경로> [임계값]")
        print("  인터랙티브: python image_postprocess.py <이미지경로> --interactive")
        print("\n예시:")
        print("  python image_postprocess.py assets/images/cat.png")
        print("  python image_postprocess.py assets/images/cat.png 180")
        print("  python image_postprocess.py assets/images/ 200")
        sys.exit(1)
    
    target = sys.argv[1]
    threshold = 200  # 기본값
    
    # 옵션 파싱
    if len(sys.argv) > 2:
        if sys.argv[2] == "--interactive":
            if os.path.isfile(target):
                threshold = interactive_threshold(target)
                convert_to_pure_bw(target, threshold_value=threshold)
            else:
                print("인터랙티브 모드는 단일 파일에만 사용 가능합니다.")
            sys.exit(0)
        else:
            try:
                threshold = int(sys.argv[2])
            except ValueError:
                print(f"잘못된 임계값: {sys.argv[2]}")
                sys.exit(1)
    
    # 파일 또는 디렉토리 처리
    if os.path.isfile(target):
        convert_to_pure_bw(target, threshold_value=threshold)
    elif os.path.isdir(target):
        process_directory(target, threshold_value=threshold)
    else:
        print(f"파일 또는 디렉토리를 찾을 수 없습니다: {target}")
        sys.exit(1)
