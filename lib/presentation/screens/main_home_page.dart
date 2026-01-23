import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/iap_service.dart';
import '../../core/services/settings_service.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/coloring_repository.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/banner_ad_widget.dart';
import 'gallery_page.dart';

/// 메인 홈 화면 - 언어 선택 및 카테고리 선택
class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage>
    with SingleTickerProviderStateMixin {
  final ColoringRepository _repository = ColoringRepository();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadCategories();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await _repository.loadCategories();
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsService>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withAlpha(25),
              colorScheme.secondary.withAlpha(40),
              colorScheme.tertiary.withAlpha(30),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 상단 앱바
              _buildAppBar(context, l10n, settings),
              // 메인 컨텐츠
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildContent(context, l10n),
                      ),
              ),
              // 배너 광고
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    SettingsService settings,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 앱 로고/타이틀
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withAlpha(76),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.palette,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          const Spacer(),
          // 언어 선택 버튼
          _buildLanguageButton(context, settings),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context, SettingsService settings) {
    return PopupMenuButton<Locale>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(50),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              SettingsService.getLanguageFlag(settings.locale),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              SettingsService.getLanguageName(settings.locale),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ],
        ),
      ),
      onSelected: (Locale locale) {
        settings.setLocale(locale);
      },
      itemBuilder: (context) => SettingsService.supportedLocales.map((locale) {
        final isSelected = locale == settings.locale;
        return PopupMenuItem<Locale>(
          value: locale,
          child: Row(
            children: [
              Text(
                SettingsService.getLanguageFlag(locale),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Text(
                SettingsService.getLanguageName(locale),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 환영 메시지
          _buildWelcomeSection(context, l10n),
          const SizedBox(height: 32),
          // 카테고리 섹션
          _buildCategorySection(context, l10n),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha(76),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.welcomeMessage,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.welcomeSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withAlpha(220),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.category_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.selectCategory,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            return _CategoryCard(
              category: _categories[index],
              onTap: () => _navigateToGallery(_categories[index]),
            );
          },
        ),
      ],
    );
  }

  void _navigateToGallery(CategoryModel category) {
    final iapService = Provider.of<IAPService>(context, listen: false);
    
    // 무료 카테고리이거나 이미 구매한 경우
    if (category.isFree || iapService.isCategoryPurchased(category.id)) {
      _openGallery(category);
    } else {
      // 잠긴 카테고리: 구매 다이얼로그 표시
      _showPurchaseDialog(category);
    }
  }

  void _openGallery(CategoryModel category) {
    final settings = Provider.of<SettingsService>(context, listen: false);
    settings.setLastCategory(category.id);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            GalleryPage(category: category),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showPurchaseDialog(CategoryModel category) {
    final l10n = AppLocalizations.of(context)!;
    final iapService = Provider.of<IAPService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.amber.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '잠긴 카테고리',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '이 카테고리를 이용하시려면 구매가 필요합니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '20개의 프리미엄 도안이 포함되어 있습니다!',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await iapService.purchaseCategory(category.id);
              if (success && mounted) {
                // 구매 성공 시 갤러리로 이동
                _openGallery(category);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('구매하기'),
          ),
        ],
      ),
    );
  }
}

/// 카테고리 카드 위젯
class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  IconData _getCategoryIcon() {
    switch (category.id) {
      case 'forest':
        return Icons.pets;
      case 'ocean':
        return Icons.water;
      case 'fairy':
        return Icons.auto_awesome;
      case 'vehicles':
        return Icons.directions_car;
      case 'dinosaurs':
        return Icons.vape_free; // 공룡 느낌의 아이콘이 없어서 대체
      case 'desserts':
        return Icons.cake;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(BuildContext context) {
    switch (category.id) {
      case 'forest':
        return Colors.green;
      case 'ocean':
        return Colors.blue;
      case 'fairy':
        return Colors.purple;
      case 'vehicles':
        return Colors.orange;
      case 'dinosaurs':
        return Colors.brown;
      case 'desserts':
        return Colors.pink;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getCategoryName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (category.id) {
      case 'forest':
        return l10n.categoryForest;
      case 'ocean':
        return l10n.categoryOcean;
      case 'fairy':
        return l10n.categoryFairy;
      case 'vehicles':
        return l10n.categoryVehicles;
      case 'dinosaurs':
        return l10n.categoryDinosaurs;
      case 'desserts':
        return l10n.categoryDesserts;
      default:
        return category.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withAlpha(50),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(30),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 배경 장식
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  _getCategoryIcon(),
                  size: 100,
                  color: color.withAlpha(25),
                ),
              ),
              // 컨텐츠
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(),
                        color: color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getCategoryName(context),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ),
              // 화살표 아이콘 또는 잠금 아이콘
              Positioned(
                right: 12,
                top: 12,
                child: category.isFree
                    ? Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: color.withAlpha(150),
                      )
                    : Icon(
                        Icons.lock,
                        size: 18,
                        color: Colors.amber.shade700,
                      ),
              ),
              // 잠금 오버레이 (비무료 카테고리인 경우)
              if (!category.isFree)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
