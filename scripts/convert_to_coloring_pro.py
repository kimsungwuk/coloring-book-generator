#!/usr/bin/env python3
"""
고품질 컬러링북 도안 변환기 (Pro 버전)

사용법:
    python convert_to_coloring_pro.py

필요한 패키지:
    pip install opencv-python numpy pillow scipy

특징:
    - 다중 스케일 에지 검출로 세밀한 디테일 보존
    - 노이즈 제거 및 선 정리
    - 부드러운 곡선 처리
    - 다양한 스타일 옵션
"""

import os
import sys
from pathlib import Path
from typing import Tuple, Optional

try:
    import cv2
    import numpy as np
    from PIL import Image, ImageFilter, ImageOps
    from scipy import ndimage
except ImportError as e:
    print(f"필요한 패키지가 설치되지 않았습니다: {e}")
    print("다음 명령어로 설치해주세요:")
    print("  pip install opencv-python numpy pillow scipy")
    sys.exit(1)


class ColoringBookConverter:
    """고품질 컬러링북 변환기 클래스"""
    
    def __init__(self):
        self.default_settings = {
            'line_thickness': 2,      # 선 두께 (1-5)
            'detail_level': 'medium', # 디테일 수준: low, medium, high
            'smooth_lines': True,     # 선 부드럽게 처리
            'remove_noise': True,     # 노이즈 제거
            'enhance_contrast': True, # 대비 향상
        }
    
    def multi_scale_edge_detection(self, gray: np.ndarray) -> np.ndarray:
        """
        다중 스케일 에지 검출
        여러 크기의 에지를 합쳐서 디테일과 큰 형태를 모두 캡처
        """
        # 다양한 블러 크기로 에지 검출
        edges_list = []
        
        for blur_size in [3, 5, 7]:
            blurred = cv2.GaussianBlur(gray, (blur_size, blur_size), 0)
            
            # Canny 에지 검출 (여러 임계값)
            edges1 = cv2.Canny(blurred, 20, 80)
            edges2 = cv2.Canny(blurred, 40, 120)
            edges3 = cv2.Canny(blurred, 60, 160)
            
            combined = cv2.bitwise_or(edges1, cv2.bitwise_or(edges2, edges3))
            edges_list.append(combined)
        
        # 모든 스케일 합치기
        final_edges = edges_list[0]
        for edges in edges_list[1:]:
            final_edges = cv2.bitwise_or(final_edges, edges)
        
        return final_edges
    
    def sobel_edge_detection(self, gray: np.ndarray) -> np.ndarray:
        """Sobel 에지 검출 - 더 부드러운 그라디언트"""
        # Sobel 연산자로 x, y 방향 그라디언트 계산
        sobelx = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
        sobely = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)
        
        # 그라디언트 크기 계산
        magnitude = np.sqrt(sobelx**2 + sobely**2)
        
        # 정규화
        magnitude = (magnitude / magnitude.max() * 255).astype(np.uint8)
        
        # 임계값 적용
        _, edges = cv2.threshold(magnitude, 30, 255, cv2.THRESH_BINARY)
        
        return edges
    
    def laplacian_edge_detection(self, gray: np.ndarray) -> np.ndarray:
        """Laplacian 에지 검출 - 모든 방향의 에지"""
        # 노이즈 제거
        blurred = cv2.GaussianBlur(gray, (3, 3), 0)
        
        # Laplacian 적용
        laplacian = cv2.Laplacian(blurred, cv2.CV_64F)
        
        # 절대값 및 정규화
        laplacian = np.abs(laplacian)
        laplacian = (laplacian / laplacian.max() * 255).astype(np.uint8)
        
        # 임계값 적용
        _, edges = cv2.threshold(laplacian, 20, 255, cv2.THRESH_BINARY)
        
        return edges
    
    def xdog_filter(self, gray: np.ndarray, sigma: float = 0.5, 
                    k: float = 1.6, p: float = 20, 
                    epsilon: float = 0.01, phi: float = 1.0) -> np.ndarray:
        """
        XDoG (eXtended Difference of Gaussians) 필터
        매우 깨끗하고 예술적인 선화 생성
        """
        # 정규화
        gray_normalized = gray.astype(np.float64) / 255.0
        
        # 두 개의 가우시안 블러
        sigma1 = sigma
        sigma2 = sigma * k
        
        g1 = cv2.GaussianBlur(gray_normalized, (0, 0), sigma1)
        g2 = cv2.GaussianBlur(gray_normalized, (0, 0), sigma2)
        
        # DoG 계산
        dog = g1 - p * g2
        
        # 임계값 함수 적용
        result = np.where(dog >= epsilon, 1.0, 1.0 + np.tanh(phi * (dog - epsilon)))
        
        # 0-255 범위로 변환
        result = (result * 255).astype(np.uint8)
        
        # 이진화
        _, binary = cv2.threshold(result, 200, 255, cv2.THRESH_BINARY)
        
        return binary
    
    def clean_and_smooth_lines(self, edges: np.ndarray, 
                                line_thickness: int = 2) -> np.ndarray:
        """선 정리 및 부드럽게 처리"""
        # 작은 노이즈 제거 (모폴로지 열기 연산)
        kernel_small = np.ones((2, 2), np.uint8)
        cleaned = cv2.morphologyEx(edges, cv2.MORPH_OPEN, kernel_small)
        
        # 끊어진 선 연결 (모폴로지 닫기 연산)
        kernel_close = np.ones((3, 3), np.uint8)
        cleaned = cv2.morphologyEx(cleaned, cv2.MORPH_CLOSE, kernel_close)
        
        # 선 두께 조절
        if line_thickness > 1:
            kernel_dilate = np.ones((line_thickness, line_thickness), np.uint8)
            cleaned = cv2.dilate(cleaned, kernel_dilate, iterations=1)
        
        # 가우시안 블러로 선 부드럽게
        smoothed = cv2.GaussianBlur(cleaned, (3, 3), 0)
        
        # 다시 이진화
        _, final = cv2.threshold(smoothed, 127, 255, cv2.THRESH_BINARY)
        
        return final
    
    def remove_small_components(self, binary: np.ndarray, 
                                 min_size: int = 50) -> np.ndarray:
        """작은 노이즈 컴포넌트 제거"""
        # 연결된 컴포넌트 찾기
        num_labels, labels, stats, _ = cv2.connectedComponentsWithStats(
            binary, connectivity=8
        )
        
        # 작은 컴포넌트 제거
        result = np.zeros_like(binary)
        for i in range(1, num_labels):  # 0은 배경
            if stats[i, cv2.CC_STAT_AREA] >= min_size:
                result[labels == i] = 255
        
        return result
    
    def enhance_for_coloring(self, img: np.ndarray) -> np.ndarray:
        """컬러링북에 적합하도록 이미지 전처리"""
        # 양방향 필터로 노이즈 제거하면서 에지 보존
        enhanced = cv2.bilateralFilter(img, 9, 75, 75)
        
        # 대비 향상
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(enhanced)
        
        return enhanced
    
    def convert_pro_quality(self, image_path: str, output_path: str,
                            style: str = 'balanced') -> bool:
        """
        고품질 도안 변환 (Pro)
        
        Args:
            image_path: 입력 이미지 경로
            output_path: 출력 이미지 경로
            style: 스타일 선택
                - 'clean': 깔끔하고 단순한 선
                - 'detailed': 세밀한 디테일 보존
                - 'balanced': 균형잡힌 (기본값)
                - 'artistic': 예술적 스케치 느낌
        
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
            
            # 전처리
            enhanced_gray = self.enhance_for_coloring(gray)
            
            if style == 'clean':
                # 깔끔한 스타일: XDoG 사용
                edges = self.xdog_filter(enhanced_gray, sigma=0.4, k=1.4, p=25)
                
            elif style == 'detailed':
                # 세밀한 스타일: 다중 스케일 + Sobel 조합
                multi_edges = self.multi_scale_edge_detection(enhanced_gray)
                sobel_edges = self.sobel_edge_detection(enhanced_gray)
                edges = cv2.bitwise_or(multi_edges, sobel_edges)
                
            elif style == 'artistic':
                # 예술적 스타일: XDoG 변형
                edges = self.xdog_filter(enhanced_gray, sigma=0.6, k=2.0, p=30, phi=0.5)
                
            else:  # balanced
                # 균형잡힌 스타일: 다중 에지 조합
                canny_edges = self.multi_scale_edge_detection(enhanced_gray)
                laplacian_edges = self.laplacian_edge_detection(enhanced_gray)
                
                # 가중 평균으로 조합
                edges = cv2.addWeighted(canny_edges, 0.7, laplacian_edges, 0.3, 0)
                _, edges = cv2.threshold(edges, 127, 255, cv2.THRESH_BINARY)
            
            # 선 정리 및 부드럽게
            cleaned = self.clean_and_smooth_lines(edges, line_thickness=2)
            
            # 작은 노이즈 제거
            cleaned = self.remove_small_components(cleaned, min_size=30)
            
            # 반전 (흰 배경에 검은 선)
            result = cv2.bitwise_not(cleaned)
            
            # 저장
            cv2.imwrite(output_path, result)
            return True
            
        except Exception as e:
            print(f"  ❌ 변환 중 오류 발생: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    def convert_ultra_quality(self, image_path: str, output_path: str) -> bool:
        """
        초고품질 도안 변환 (Ultra)
        여러 기법을 조합하여 최상의 결과물 생성
        """
        try:
            # 이미지 읽기
            img = cv2.imread(image_path)
            if img is None:
                print(f"  ❌ 이미지를 읽을 수 없습니다: {image_path}")
                return False
            
            # 그레이스케일
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            
            # 1. 전처리: 노이즈 제거 + 대비 향상
            denoised = cv2.fastNlMeansDenoising(gray, None, 10, 7, 21)
            enhanced = self.enhance_for_coloring(denoised)
            
            # 2. 다양한 에지 검출 기법 적용
            # XDoG (깨끗한 주요 선)
            xdog_edges = self.xdog_filter(enhanced, sigma=0.5, k=1.6, p=22)
            
            # 다중 스케일 Canny (디테일)
            multi_edges = self.multi_scale_edge_detection(enhanced)
            
            # 3. 에지 조합
            # XDoG를 기본으로, 다중 스케일로 디테일 보강
            combined = cv2.bitwise_or(
                cv2.bitwise_not(xdog_edges), 
                multi_edges
            )
            
            # 4. 선 정리
            # 모폴로지로 끊어진 선 연결
            kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2, 2))
            cleaned = cv2.morphologyEx(combined, cv2.MORPH_CLOSE, kernel)
            
            # 5. 노이즈 제거
            cleaned = self.remove_small_components(cleaned, min_size=40)
            
            # 6. 선 두께 균일화
            kernel_uniform = np.ones((2, 2), np.uint8)
            cleaned = cv2.dilate(cleaned, kernel_uniform, iterations=1)
            cleaned = cv2.erode(cleaned, kernel_uniform, iterations=1)
            
            # 7. 최종 부드럽게 처리
            smoothed = cv2.GaussianBlur(cleaned, (3, 3), 0)
            _, final = cv2.threshold(smoothed, 127, 255, cv2.THRESH_BINARY)
            
            # 8. 반전 (흰 배경에 검은 선)
            result = cv2.bitwise_not(final)
            
            # 저장
            cv2.imwrite(output_path, result)
            return True
            
        except Exception as e:
            print(f"  ❌ 변환 중 오류 발생: {e}")
            import traceback
            traceback.print_exc()
            return False


def main():
    # 프로젝트 루트 경로 설정
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    
    raw_image_dir = project_root / "assets" / "raw_image"
    output_dir = project_root / "assets" / "images"
    
    # 디렉토리 확인 및 생성
    if not raw_image_dir.exists():
        raw_image_dir.mkdir(parents=True, exist_ok=True)
        print(f"📁 원본 이미지 폴더를 생성했습니다: {raw_image_dir}")
        print("   변환할 이미지를 넣어주세요.")
        sys.exit(0)
    
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
    
    print("=" * 65)
    print("🎨 고품질 컬러링북 도안 변환기 (Pro)")
    print("=" * 65)
    print(f"📂 입력 폴더: {raw_image_dir}")
    print(f"📂 출력 폴더: {output_dir}")
    print(f"📷 발견된 이미지: {len(image_files)}개")
    print("-" * 65)
    
    # 변환 방식 선택
    print("\n🎯 변환 품질/스타일을 선택하세요:")
    print()
    print("  [Pro 품질]")
    print("    1. Clean (깔끔)    - 단순하고 깨끗한 선")
    print("    2. Detailed (세밀) - 디테일 보존")
    print("    3. Balanced (균형) - 깔끔함과 디테일의 균형")
    print("    4. Artistic (예술) - 스케치 느낌")
    print()
    print("  [Ultra 품질]")
    print("    5. Ultra           - 최고 품질 (모든 기법 조합)")
    print()
    print("    6. 모든 스타일 비교 (5가지 모두 생성)")
    
    try:
        choice = input("\n선택 (1-6, 기본값 5): ").strip() or "5"
    except EOFError:
        choice = "5"
    
    if choice not in ["1", "2", "3", "4", "5", "6"]:
        choice = "5"
    
    print("-" * 65)
    
    converter = ColoringBookConverter()
    
    style_map = {
        "1": ("clean", "Clean"),
        "2": ("detailed", "Detailed"),
        "3": ("balanced", "Balanced"),
        "4": ("artistic", "Artistic"),
        "5": ("ultra", "Ultra"),
    }
    
    success_count = 0
    fail_count = 0
    
    for i, image_file in enumerate(image_files, 1):
        print(f"\n[{i}/{len(image_files)}] 처리 중: {image_file.name}")
        
        input_path = str(image_file)
        base_name = image_file.stem
        
        if choice == "6":
            # 모든 스타일로 변환
            styles = [
                ("clean", "Clean"),
                ("detailed", "Detailed"),
                ("balanced", "Balanced"),
                ("artistic", "Artistic"),
                ("ultra", "Ultra"),
            ]
            
            for style_id, style_name in styles:
                output_filename = f"{base_name}_{style_id}.png"
                output_path = str(output_dir / output_filename)
                
                if style_id == "ultra":
                    result = converter.convert_ultra_quality(input_path, output_path)
                else:
                    result = converter.convert_pro_quality(
                        input_path, output_path, style=style_id
                    )
                
                if result:
                    print(f"  ✅ {style_name}: {output_filename}")
                    success_count += 1
                else:
                    fail_count += 1
        else:
            # 선택된 스타일로 변환
            style_id, style_name = style_map[choice]
            output_filename = f"{base_name}_{style_id}.png"
            output_path = str(output_dir / output_filename)
            
            if style_id == "ultra":
                result = converter.convert_ultra_quality(input_path, output_path)
            else:
                result = converter.convert_pro_quality(
                    input_path, output_path, style=style_id
                )
            
            if result:
                print(f"  ✅ {style_name} 스타일로 저장됨: {output_filename}")
                success_count += 1
            else:
                fail_count += 1
    
    print("\n" + "=" * 65)
    print("📊 변환 완료!")
    print(f"   ✅ 성공: {success_count}개")
    if fail_count > 0:
        print(f"   ❌ 실패: {fail_count}개")
    print(f"   📂 출력 폴더: {output_dir}")
    print("=" * 65)


if __name__ == "__main__":
    main()
