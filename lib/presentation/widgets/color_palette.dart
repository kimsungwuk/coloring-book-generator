import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../providers/coloring_provider.dart';

/// 색상 팔레트 위젯
class ColorPalette extends StatelessWidget {
  const ColorPalette({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ColoringProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 80,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: AppConstants.defaultColors.length + 1, // +1 for color picker
            itemBuilder: (context, index) {
              if (index == 0) {
                // 컬러 피커 버튼
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ColorPickerButton(
                    onTap: () => _showColorPicker(context, provider),
                  ),
                );
              }

              final colorIndex = index - 1;
              final color = AppConstants.defaultColors[colorIndex];
              final isSelected = provider.selectedColor == color;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _ColorSwatch(
                  color: color,
                  isSelected: isSelected,
                  onTap: () => provider.selectColor(color),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 컬러 피커 다이얼로그 표시
  void _showColorPicker(BuildContext context, ColoringProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        Color pickedColor = provider.selectedColor;
        return AlertDialog(
          title: Text(l10n.pickColor),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: provider.selectedColor,
              onColorChanged: (color) => pickedColor = color,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                provider.selectColor(pickedColor);
                Navigator.pop(context);
              },
              child: Text(l10n.select),
            ),
          ],
        );
      },
    );
  }
}

/// 컬러 피커 실행 버튼
class _ColorPickerButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ColorPickerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Colors.red,
              Colors.orange,
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.indigo,
              Colors.purple,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.colorize,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

/// 개별 색상 스와치 위젯
class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 56 : 48,
        height: isSelected ? 56 : 48,
        margin: EdgeInsets.only(top: isSelected ? 0 : 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(isSelected ? 128 : 51),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: _getContrastColor(color),
                size: 24,
              )
            : null,
      ),
    );
  }

  /// 배경색에 따른 대비 색상 반환
  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
