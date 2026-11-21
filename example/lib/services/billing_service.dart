import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Real Google Play Billing & In-App Purchase service with sandbox fallback.
///
/// Connects to Google Play Billing via [InAppPurchase.instance] while gracefully
/// providing an interactive sandbox/mock layer when running on desktop, web, or
/// unconfigured test devices so UI and purchase state flows can be verified everywhere.
class BillingService extends ChangeNotifier {
  static final BillingService instance = BillingService._();
  BillingService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool _isPro = false;
  bool _isLoading = false;
  String? _statusMessage;
  List<ProductDetails> _products = [];

  static const String productLifetimePro = 'puzzak_pro_lifetime';
  static const String productMonthlyPro = 'puzzak_pro_monthly';
  static const Set<String> _kProductIds = {
    productLifetimePro,
    productMonthlyPro,
  };

  bool get isAvailable => _isAvailable;
  bool get isPro => _isPro;
  bool get isLoading => _isLoading;
  String? get statusMessage => _statusMessage;
  List<ProductDetails> get products => List.unmodifiable(_products);

  /// Initializes the purchase stream listener and queries available products.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _subscription?.cancel();
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          _statusMessage = 'Purchase stream error: $error';
          _isLoading = false;
          notifyListeners();
        },
      );

      _isAvailable = await _iap.isAvailable();
      if (_isAvailable) {
        final ProductDetailsResponse response =
            await _iap.queryProductDetails(_kProductIds);
        if (response.error == null) {
          _products = response.productDetails;
          _statusMessage = 'Connected to store (${_products.length} products loaded)';
        } else {
          _statusMessage = 'Store query error: ${response.error!.message}';
        }
      } else {
        _statusMessage = 'Play Billing not available (Desktop/Sandbox mode active)';
      }
    } catch (e) {
      _isAvailable = false;
      _statusMessage = 'Billing init fallback: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _statusMessage = 'Purchase pending authorization...';
          _isLoading = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final bool valid = _verifyPurchase(purchaseDetails);
          if (valid) {
            _isPro = true;
            _statusMessage = purchaseDetails.status == PurchaseStatus.restored
                ? 'Purchases successfully restored!'
                : 'Purchase successful! Pro privileges activated.';
          } else {
            _statusMessage = 'Purchase verification failed.';
          }
          if (purchaseDetails.pendingCompletePurchase) {
            _iap.completePurchase(purchaseDetails);
          }
          _isLoading = false;
          break;
        case PurchaseStatus.error:
          _statusMessage = 'Purchase failed: ${purchaseDetails.error?.message}';
          _isLoading = false;
          break;
        case PurchaseStatus.canceled:
          _statusMessage = 'Purchase canceled by user.';
          _isLoading = false;
          break;
      }
    }
    notifyListeners();
  }

  bool _verifyPurchase(PurchaseDetails purchaseDetails) {
    // In production, verify transaction receipt against backend server
    return purchaseDetails.productID == productLifetimePro ||
        purchaseDetails.productID == productMonthlyPro;
  }

  /// Triggers a purchase flow for the specified product.
  Future<bool> buyProduct(ProductDetails product) async {
    _isLoading = true;
    _statusMessage = 'Initiating purchase for ${product.title}...';
    notifyListeners();

    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _statusMessage = 'Store purchase error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Restores previous purchases across devices.
  Future<void> restorePurchases() async {
    _isLoading = true;
    _statusMessage = 'Querying past purchases...';
    notifyListeners();

    try {
      await _iap.restorePurchases();
    } catch (e) {
      _statusMessage = 'Restore error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Simulator helper for desktop / testing environments.
  void toggleSimulatedPro(bool active) {
    _isPro = active;
    _statusMessage = active
        ? 'Sandbox: Simulated Lifetime Pro granted!'
        : 'Sandbox: Pro status revoked.';
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
