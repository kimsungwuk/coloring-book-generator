import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 인앱 구매 서비스 - 카테고리 잠금 해제 관리
class IAPService extends ChangeNotifier {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // 제품 ID 정의 (Google Play Console에서 설정한 ID와 일치해야 함)
  static const String productCategoryBundle = 'category_bundle_all';
  static const String productOcean = 'category_ocean';
  static const String productFairy = 'category_fairy';
  static const String productVehicles = 'category_vehicles';
  static const String productDinosaurs = 'category_dinosaurs';
  static const String productDesserts = 'category_desserts';
  
  static const Set<String> _productIds = {
    productCategoryBundle,
    productOcean,
    productFairy,
    productVehicles,
    productDinosaurs,
    productDesserts,
  };

  // 구매된 카테고리 상태
  final Set<String> _purchasedCategories = {};
  bool _isAvailable = false;
  bool _isLoading = true;
  List<ProductDetails> _products = [];
  
  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  List<ProductDetails> get products => _products;

  /// 서비스 초기화
  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    
    if (!_isAvailable) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    // 구매 스트림 리스닝
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: _onDone,
      onError: _onError,
    );

    // 저장된 구매 상태 로드
    await _loadPurchasedCategories();
    
    // 제품 정보 로드
    await _loadProducts();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = 
          await _iap.queryProductDetails(_productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('[IAP] Products not found: ${response.notFoundIDs}');
      }
      
      _products = response.productDetails;
      debugPrint('[IAP] Loaded ${_products.length} products');
    } catch (e) {
      debugPrint('[IAP] Error loading products: $e');
    }
  }

  Future<void> _loadPurchasedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final purchased = prefs.getStringList('purchased_categories') ?? [];
      _purchasedCategories.addAll(purchased);
      debugPrint('[IAP] Loaded purchased categories: $_purchasedCategories');
    } catch (e) {
      debugPrint('[IAP] Error loading purchased categories: $e');
    }
  }

  Future<void> _savePurchasedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'purchased_categories', 
        _purchasedCategories.toList(),
      );
    } catch (e) {
      debugPrint('[IAP] Error saving purchased categories: $e');
    }
  }

  /// 카테고리가 구매되었는지 확인
  bool isCategoryPurchased(String categoryId) {
    // forest는 항상 무료
    if (categoryId == 'forest') return true;
    // 전체 번들 구매 시 모든 카테고리 잠금 해제
    if (_purchasedCategories.contains(productCategoryBundle)) return true;
    // 개별 카테고리 구매 확인
    return _purchasedCategories.contains(_getCategoryProductId(categoryId));
  }

  String _getCategoryProductId(String categoryId) {
    switch (categoryId) {
      case 'ocean': return productOcean;
      case 'fairy': return productFairy;
      case 'vehicles': return productVehicles;
      case 'dinosaurs': return productDinosaurs;
      case 'desserts': return productDesserts;
      default: return '';
    }
  }

  /// 카테고리 구매 시작
  Future<bool> purchaseCategory(String categoryId) async {
    if (!_isAvailable) {
      debugPrint('[IAP] Store not available');
      return false;
    }

    final productId = _getCategoryProductId(categoryId);
    final product = _products.where((p) => p.id == productId).firstOrNull;
    
    if (product == null) {
      debugPrint('[IAP] Product not found: $productId');
      // 개발 환경에서는 바로 잠금 해제 (테스트용)
      if (kDebugMode) {
        await _unlockCategory(productId);
        return true;
      }
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    
    try {
      // 비소모성 상품으로 구매
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      return true;
    } catch (e) {
      debugPrint('[IAP] Purchase error: $e');
      return false;
    }
  }

  /// 전체 번들 구매
  Future<bool> purchaseAllCategories() async {
    if (!_isAvailable) {
      debugPrint('[IAP] Store not available');
      return false;
    }

    final product = _products.where((p) => p.id == productCategoryBundle).firstOrNull;
    
    if (product == null) {
      debugPrint('[IAP] Bundle product not found');
      if (kDebugMode) {
        await _unlockCategory(productCategoryBundle);
        return true;
      }
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    
    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      return true;
    } catch (e) {
      debugPrint('[IAP] Bundle purchase error: $e');
      return false;
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('[IAP] Purchase pending: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('[IAP] Purchase error: ${purchaseDetails.error}');
        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        _unlockCategory(purchaseDetails.productID);
        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _unlockCategory(String productId) async {
    _purchasedCategories.add(productId);
    await _savePurchasedCategories();
    notifyListeners();
    debugPrint('[IAP] Category unlocked: $productId');
  }

  /// 구매 복원
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    await _iap.restorePurchases();
  }

  void _onDone() {
    _subscription?.cancel();
  }

  void _onError(dynamic error) {
    debugPrint('[IAP] Stream error: $error');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
