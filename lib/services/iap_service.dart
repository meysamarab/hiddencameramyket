import 'package:flutter_poolakey/flutter_poolakey.dart';

class IAPService {
  // Replace with actual RSA key from Bazaar panel
  static const String _rsaKey = "YOUR_RSA_PUBLIC_KEY_HERE";
  static const String premiumProductId = "premium_subscription";

  Future<bool> init() async {
    try {
      bool success = false;
      await FlutterPoolakey.connect(
        _rsaKey,
        onSucceed: () => success = true,
        onFailed: (message) => success = false,
      );
      return success;
    } catch (e) {
      print("Poolakey connect error: $e");
      return false;
    }
  }

  Future<bool> checkSubscription() async {
    try {
      final purchases = await FlutterPoolakey.getAllSubscribedProducts();
      return purchases.any((p) => p.productId == premiumProductId);
    } catch (e) {
      print("Check subscription error: $e");
      return false;
    }
  }

  Future<bool> purchasePremium() async {
    try {
      final purchaseInfo = await FlutterPoolakey.subscribe(
        premiumProductId,
        payload: "premium_upgrade",
      );
      return purchaseInfo.productId == premiumProductId;
    } catch (e) {
      print("Purchase error: $e");
      return false;
    }
  }
}
