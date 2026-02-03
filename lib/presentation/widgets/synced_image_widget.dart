import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/repositories/coloring_repository.dart';

/// 동기화된 이미지(로컬 파일) 또는 번들 에셋을 자동으로 로드하는 위젯
/// 
/// 우선순위:
/// 1. 로컬에 다운로드된 이미지 파일
/// 2. 번들된 에셋 이미지
class SyncedImageWidget extends StatefulWidget {
  final String assetPath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SyncedImageWidget({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<SyncedImageWidget> createState() => _SyncedImageWidgetState();
}

class _SyncedImageWidgetState extends State<SyncedImageWidget> {
  final ColoringRepository _repository = ColoringRepository();
  
  String? _localFilePath;
  bool _isLoading = true;
  bool _useLocalFile = false;

  @override
  void initState() {
    super.initState();
    if (!_isNetworkImage()) {
      _checkLocalFile();
    } else {
      _isLoading = false;
    }
  }

  @override
  void didUpdateWidget(SyncedImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      if (!_isNetworkImage()) {
        _checkLocalFile();
      } else {
        setState(() {
          _isLoading = false;
          _useLocalFile = false;
        });
      }
    }
  }

  bool _isNetworkImage() {
    return widget.assetPath.startsWith('http');
  }

  /// 로컬에 다운로드된 파일이 있는지 확인
  Future<void> _checkLocalFile() async {
    if (!mounted) return;
    if (_isNetworkImage()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final (path, isFile) = await _repository.resolveImagePath(widget.assetPath);
      
      if (isFile) {
        final file = File(path);
        if (await file.exists()) {
          if (mounted) {
            setState(() {
              _localFilePath = path;
              _useLocalFile = true;
              _isLoading = false;
            });
          }
          return;
        }
      }
      
      // 로컬 파일이 없으면 에셋 사용
      if (mounted) {
        setState(() {
          _useLocalFile = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking local file: $e');
      if (mounted) {
        setState(() {
          _useLocalFile = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isNetworkImage()) {
      return Image.network(
        widget.assetPath,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Network load error for ${widget.assetPath}: $error');
          return widget.errorWidget ?? _buildPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return widget.placeholder ?? _buildPlaceholder();
        },
      );
    }

    // 로컬 파일/에셋 처리
    if (_isLoading) {
      return _buildAssetImage();
    }

    if (_useLocalFile && _localFilePath != null) {
      return Image.file(
        File(_localFilePath!),
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Local file load error: $error');
          return _buildAssetImage();
        },
      );
    }

    return _buildAssetImage();
  }

  Widget _buildAssetImage() {
    return Image.asset(
      widget.assetPath,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Asset load error for ${widget.assetPath}: $error');
        return widget.errorWidget ?? _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            color: Colors.grey.shade400,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            'Image',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
