import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coloring_provider.dart';

/// 색칠 캔버스 위젯
class ColoringCanvas extends StatelessWidget {
  const ColoringCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ColoringProvider>(
      builder: (context, provider, child) {
        if (provider.displayImage == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            // 인터랙티브 캔버스
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final imageSize = provider.getImageSize();
                    if (imageSize == null) return const SizedBox();

                    // 이미지 비율 유지하며 크기 계산
                    final aspectRatio = imageSize.width / imageSize.height;
                    double canvasWidth, canvasHeight;

                    if (constraints.maxWidth / constraints.maxHeight > aspectRatio) {
                      canvasHeight = constraints.maxHeight;
                      canvasWidth = canvasHeight * aspectRatio;
                    } else {
                      canvasWidth = constraints.maxWidth;
                      canvasHeight = canvasWidth / aspectRatio;
                    }

                    return GestureDetector(
                      onTapUp: (details) {
                        if (provider.isProcessing) return;

                        // 탭 위치를 캔버스 내부 좌표로 변환
                        final localPosition = details.localPosition;

                        provider.fillAtPosition(
                          localPosition,
                          Size(canvasWidth, canvasHeight),
                        );
                      },
                      child: Container(
                        width: canvasWidth,
                        height: canvasHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CustomPaint(
                            size: Size(canvasWidth, canvasHeight),
                            painter: _ImagePainter(
                              image: provider.displayImage!,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // 로딩 오버레이
            if (provider.isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha(76),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 이미지 페인터
class _ImagePainter extends CustomPainter {
  final ui.Image image;

  _ImagePainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.high;

    // 이미지를 캔버스 크기에 맞게 그리기
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant _ImagePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
