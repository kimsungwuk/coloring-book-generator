import 'dart:ui';

/// 색칠 작업 기록 (Undo/Redo용)
class ColoringAction {
  final int x;
  final int y;
  final Color color;
  final List<Offset> filledPixels;

  const ColoringAction({
    required this.x,
    required this.y,
    required this.color,
    required this.filledPixels,
  });
}
