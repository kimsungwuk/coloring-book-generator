import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/coloring_repository.dart';
import 'main_home_page.dart';

/// 스플래시 화면 - 앱 시작 시 이미지 동기화 수행
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final ColoringRepository _repository = ColoringRepository();
  
  String _statusText = '';
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // 이미지 동기화 및 네비게이션
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // 최소 스플래시 시간 보장
    final minSplashFuture = Future.delayed(
      const Duration(seconds: AppConstants.splashDuration),
    );

    // 이미지 동기화 시도
    await _syncImages();

    // 최소 스플래시 시간 대기
    await minSplashFuture;

    // 홈 화면으로 이동
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainHomePage(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  Future<void> _syncImages() async {
    debugPrint('[Splash] Starting image sync...');
    try {
      // 동기화 필요 여부 확인
      final needsSync = await _repository.needsSync();
      debugPrint('[Splash] needsSync: $needsSync');
      
      if (needsSync) {
        setState(() {
          _isSyncing = true;
          _statusText = 'Checking for new images...';
        });

        debugPrint('[Splash] Calling syncImages...');
        final (downloaded, total) = await _repository.syncImages(
          onProgress: (current, totalPages) {
            debugPrint('[Splash] Sync progress: $current/$totalPages');
            if (mounted) {
              setState(() {
                _statusText = 'Syncing images ($current/$totalPages)';
              });
            }
          },
        );

        debugPrint('[Splash] Sync completed: downloaded=$downloaded, total=$total');
        
        if (mounted) {
          if (downloaded > 0) {
            setState(() {
              _statusText = '$downloaded new images downloaded!';
            });
          } else {
            setState(() {
              _statusText = 'All images up to date';
            });
          }
        }
      } else {
        debugPrint('[Splash] Sync not needed, skipping');
      }
    } catch (e) {
      debugPrint('[Splash] Sync error: $e');
      if (mounted) {
        setState(() {
          _statusText = 'Offline mode';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, _) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 앱 아이콘
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(51),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.palette,
                            size: 60,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // 앱 이름
                        Text(
                          AppConstants.appName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                        ),
                        const SizedBox(height: 48),
                        // 로딩 인디케이터
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        // 동기화 상태 텍스트
                        if (_statusText.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          AnimatedOpacity(
                            opacity: _statusText.isNotEmpty ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _statusText,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
