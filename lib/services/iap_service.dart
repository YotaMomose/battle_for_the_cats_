import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// アプリ内課金（IAP）を管理するサービス
class IapService extends ChangeNotifier {
  static final IapService _instance = IapService._internal();
  factory IapService() => _instance;
  IapService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // 商品IDの定義
  static const String supporterProductId = 'supporter_pack';
  static const String removeAdsProductId = 'remove_ads';

  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isLoading = true;

  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;

  /// 購入完了時に呼ばれるコールバック
  Future<void> Function(PurchaseDetails)? _onPurchaseCompleted;

  /// 初期化
  Future<void> initialize({
    Future<void> Function(PurchaseDetails)? onPurchaseCompleted,
  }) async {
    _onPurchaseCompleted = onPurchaseCompleted;

    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) {
        debugPrint('IapService Stream Error: $error');
      },
    );

    try {
      _isAvailable = await _iap.isAvailable();
      if (_isAvailable) {
        await _loadProducts();
      }
    } catch (e) {
      debugPrint('IapService Initialization Error: $e');
      _isAvailable = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 商品情報の取得
  Future<void> _loadProducts() async {
    const Set<String> ids = {supporterProductId, removeAdsProductId};
    final ProductDetailsResponse response = await _iap.queryProductDetails(ids);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
    notifyListeners();
  }

  /// 購入リクエスト（消耗型）
  Future<void> buySupporter() async {
    if (!_isAvailable) return;

    final product = _products.firstWhere(
      (p) => p.id == supporterProductId,
      orElse: () => throw Exception('Product not found'),
    );

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    // 投げ銭形式（何度も購入可能）なので buyConsumable を使用
    await _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  /// 広告非表示の購入リクエスト（非消耗型または投げ銭形式）
  /// ここでは何度も購入可能な投げ銭形式（応援の簡易版）として扱う
  Future<void> buyRemoveAds() async {
    if (!_isAvailable) return;

    final product = _products.firstWhere(
      (p) => p.id == removeAdsProductId,
      orElse: () => throw Exception('Product not found'),
    );

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  /// 購入状態の更新通知
  Future<void> _onPurchaseUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // 保留中
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase Error: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // 購入成功またはリストア
          if (_onPurchaseCompleted != null) {
            await _onPurchaseCompleted!(purchaseDetails);
          }
        }

        // 購入完了をストアに通知（これを行わないと返金される場合がある）
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
