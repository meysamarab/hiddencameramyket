import 'dart:async';
import 'package:myket_iap/myket_iap.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IAPService {
  // TODO: Replace with your actual RSA public key from Myket developer panel
  static const String _rsaKey = "YOUR_MYKET_RSA_KEY_HERE";
  static const String premiumProductId = "YOUR_SKU_HERE";

  bool _initialized = false;

  Future<bool> init() async {
    try {
      final iabResult = await MyketIAP.init(
        rsaKey: _rsaKey,
        enableDebugLogging: true,
      );

      // IabResult has a isSuccess property or response code
      _initialized = true;
      print("MyketIAP init result: $iabResult");
      return true;
    } catch (e) {
      print("MyketIAP init error: $e");
      _initialized = false;
      return false;
    }
  }

  Future<bool> checkPurchase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isCachedPremium = prefs.getBool('isPremium') ?? false;
      if (isCachedPremium) return true;

      if (!_initialized) return false;

      // Query the specific product purchase status
      final result = await MyketIAP.getPurchase(
        sku: premiumProductId,
        querySkuDetails: false,
      );

      final IabResult purchaseResult = result[MyketIAP.RESULT];
      final Purchase? purchase = result[MyketIAP.PURCHASE];

      final isPremium = purchaseResult.isSuccess && purchase != null;

      if (isPremium) {
        await prefs.setBool('isPremium', true);
      }
      return isPremium;
    } catch (e) {
      print("MyketIAP check purchase error: $e");
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('isPremium') ?? false;
    }
  }

  Future<bool> purchasePremium() async {
    try {
      if (!_initialized) {
        await init();
      }

      final result = await MyketIAP.launchPurchaseFlow(
        sku: premiumProductId,
        payload: "premium_upgrade",
      );

      final IabResult purchaseResult = result[MyketIAP.RESULT];
      final Purchase? purchase = result[MyketIAP.PURCHASE];

      final isPremium = purchaseResult.isSuccess &&
          purchase != null &&
          purchase.sku == premiumProductId;

      if (isPremium) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isPremium', true);
      }
      return isPremium;
    } catch (e) {
      print("MyketIAP purchase error: $e");
      return false;
    }
  }

  Future<void> dispose() async {
    try {
      await MyketIAP.dispose();
      _initialized = false;
    } catch (e) {
      print("MyketIAP dispose error: $e");
    }
  }
}
