import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/flood_fill_service.dart';
import '../../data/repositories/coloring_repository.dart';

/// 색칠 상태 관리 Provider
class ColoringProvider extends ChangeNotifier {
  /// 현재 선택된 색상
  Color _selectedColor = AppConstants.defaultColors[0];
  Color get selectedColor => _selectedColor;

  /// 이미지 데이터
  ImageData? _imageData;
  ImageData? get imageData => _imageData;

  /// 렌더링용 이미지
  ui.Image? _displayImage;
  ui.Image? get displayImage => _displayImage;

  /// 원본 이미지 데이터 (Clear용)
  ImageData? _originalImageData;

  /// Undo/Redo 스택
  final List<Uint8List> _undoStack = [];
  final List<Uint8List> _redoStack = [];

  /// 최대 Undo 횟수
  static const int _maxUndoSteps = 20;

  /// 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 처리 중 상태
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  /// Undo 가능 여부
  bool get canUndo => _undoStack.isNotEmpty;

  /// Redo 가능 여부
  bool get canRedo => _redoStack.isNotEmpty;

  /// 색상 선택
  void selectColor(Color color) {
    _selectedColor = color;
    notifyListeners();
  }

  /// 이미지 로드 (동기화된 이미지 파일 또는 번들 에셋 자동 판단)
  Future<void> loadImage(String assetPath) async {
    _isLoading = true;
    notifyListeners();

    try {
      // ColoringRepository를 통해 이미지 경로 해결
      final repository = ColoringRepository();
      final (resolvedPath, isFile) = await repository.resolveImagePath(assetPath);
      
      final data = await FloodFillService.loadImageAuto(resolvedPath, isFile: isFile);
      if (data != null) {
        _imageData = data;
        _originalImageData = ImageData(
          pixels: Uint8List.fromList(data.pixels),
          width: data.width,
          height: data.height,
        );
        _displayImage = await FloodFillService.pixelsToImage(
          data.pixels,
          data.width,
          data.height,
        );
        _undoStack.clear();
        _redoStack.clear();
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 저장된 진행상황에서 이미지 로드
  Future<void> loadImageFromProgress(
    String assetPath,
    Uint8List progressPixels,
    int width,
    int height,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 원본 이미지 먼저 로드 (Clear용) - 동기화된 이미지 지원
      final repository = ColoringRepository();
      final (resolvedPath, isFile) = await repository.resolveImagePath(assetPath);
      
      final originalData = await FloodFillService.loadImageAuto(resolvedPath, isFile: isFile);
      if (originalData != null) {
        _originalImageData = ImageData(
          pixels: Uint8List.fromList(originalData.pixels),
          width: originalData.width,
          height: originalData.height,
        );
      }

      // 진행상황 데이터로 현재 이미지 설정
      _imageData = ImageData(
        pixels: progressPixels,
        width: width,
        height: height,
      );
      _displayImage = await FloodFillService.pixelsToImage(
        progressPixels,
        width,
        height,
      );
      _undoStack.clear();
      _redoStack.clear();
    } catch (e) {
      debugPrint('Error loading image from progress: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 탭 위치에 색칠
  Future<void> fillAtPosition(Offset position, Size canvasSize) async {
    if (_imageData == null || _isProcessing) return;

    _isProcessing = true;
    notifyListeners();

    try {
      // 캔버스 좌표를 이미지 좌표로 변환
      final double scaleX = _imageData!.width / canvasSize.width;
      final double scaleY = _imageData!.height / canvasSize.height;
      final int x = (position.dx * scaleX).toInt();
      final int y = (position.dy * scaleY).toInt();

      // 현재 상태를 Undo 스택에 저장
      _saveToUndoStack();

      // Flood Fill 실행
      final Uint8List? filledPixels = await FloodFillService.floodFill(
        imageBytes: _imageData!.pixels,
        width: _imageData!.width,
        height: _imageData!.height,
        startX: x,
        startY: y,
        fillColor: _selectedColor,
      );

      if (filledPixels != null) {
        _imageData = _imageData!.copyWith(pixels: filledPixels);
        _displayImage = await FloodFillService.pixelsToImage(
          filledPixels,
          _imageData!.width,
          _imageData!.height,
        );
        // Redo 스택 초기화
        _redoStack.clear();
      } else {
        // 채우기가 실패하면 Undo 스택에서 제거
        if (_undoStack.isNotEmpty) {
          _undoStack.removeLast();
        }
      }
    } catch (e) {
      debugPrint('Error filling: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Undo 스택에 현재 상태 저장
  void _saveToUndoStack() {
    if (_imageData == null) return;

    _undoStack.add(Uint8List.fromList(_imageData!.pixels));
    
    // 최대 Undo 횟수 초과 시 오래된 것 제거
    while (_undoStack.length > _maxUndoSteps) {
      _undoStack.removeAt(0);
    }
  }

  /// Undo 실행
  Future<void> undo() async {
    if (!canUndo || _imageData == null || _isProcessing) return;

    _isProcessing = true;
    notifyListeners();

    try {
      // 현재 상태를 Redo 스택에 저장
      _redoStack.add(Uint8List.fromList(_imageData!.pixels));

      // Undo 스택에서 이전 상태 복원
      final Uint8List previousPixels = _undoStack.removeLast();
      _imageData = _imageData!.copyWith(pixels: previousPixels);
      _displayImage = await FloodFillService.pixelsToImage(
        previousPixels,
        _imageData!.width,
        _imageData!.height,
      );
    } catch (e) {
      debugPrint('Error undoing: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Redo 실행
  Future<void> redo() async {
    if (!canRedo || _imageData == null || _isProcessing) return;

    _isProcessing = true;
    notifyListeners();

    try {
      // 현재 상태를 Undo 스택에 저장
      _undoStack.add(Uint8List.fromList(_imageData!.pixels));

      // Redo 스택에서 상태 복원
      final Uint8List nextPixels = _redoStack.removeLast();
      _imageData = _imageData!.copyWith(pixels: nextPixels);
      _displayImage = await FloodFillService.pixelsToImage(
        nextPixels,
        _imageData!.width,
        _imageData!.height,
      );
    } catch (e) {
      debugPrint('Error redoing: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// 원본으로 초기화
  Future<void> clear() async {
    if (_originalImageData == null || _isProcessing) return;

    _isProcessing = true;
    notifyListeners();

    try {
      // 현재 상태를 Undo 스택에 저장
      _saveToUndoStack();

      _imageData = ImageData(
        pixels: Uint8List.fromList(_originalImageData!.pixels),
        width: _originalImageData!.width,
        height: _originalImageData!.height,
      );
      _displayImage = await FloodFillService.pixelsToImage(
        _imageData!.pixels,
        _imageData!.width,
        _imageData!.height,
      );
      _redoStack.clear();
    } catch (e) {
      debugPrint('Error clearing: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// 현재 이미지 픽셀 데이터 반환 (저장용)
  Uint8List? getCurrentPixels() {
    return _imageData?.pixels;
  }

  /// 이미지 크기 반환
  Size? getImageSize() {
    if (_imageData == null) return null;
    return Size(_imageData!.width.toDouble(), _imageData!.height.toDouble());
  }

  @override
  void dispose() {
    _undoStack.clear();
    _redoStack.clear();
    super.dispose();
  }
}
