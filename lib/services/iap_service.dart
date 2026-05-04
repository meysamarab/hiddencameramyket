import 'dart:async';
import 'package:myket_iap/myket_iap.dart';
import 'package:myket_iap/util/iab_result.dart';
import 'package:myket_iap/util/purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IAPService {
  static const String _rsaKey = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCJ5Qsz4IuWdlXD/+7uLORkNXvFncUb/Y/nuq4rJntCSznXi5isAjkZYQQQGK8owiuKCA/kZJbICOTXA8+hC7KB744J5MksX18mJmbg1djarrG+QryEOMMh864s3o6ZJmG83GDbqZkuZJH/MMrsLZssw6FLXW9qifOp1T+ipaSZLQIDAQAB";
  static const String premiumProductId = "pooli";

  bool _initialized = false;

  Future<bool> init() async {
    try {
      final IabResult? iabResult = await MyketIAP.init(
        rsaKey: _rsaKey,
        enableDebugLogging: false,
      );

      _initialized = iabResult != null && iabResult.isSuccess();
      print("MyketIAP init result: $iabResult");
      return _initialized;
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
      final Map result = await MyketIAP.getPurchase(
        sku: premiumProductId,
        querySkuDetails: false,
      );

      final IabResult? purchaseResult = result[MyketIAP.RESULT];
      final Purchase? purchase = result[MyketIAP.PURCHASE];

      final isPremium = purchaseResult != null && purchaseResult.isSuccess() && purchase != null;

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

      final Map result = await MyketIAP.launchPurchaseFlow(
        sku: premiumProductId,
        payload: "premium_upgrade",
      );

      final IabResult? purchaseResult = result[MyketIAP.RESULT];
      final Purchase? purchase = result[MyketIAP.PURCHASE];

      final isPremium = purchaseResult != null &&
          purchaseResult.isSuccess() &&
          purchase != null &&
          purchase.mSku == premiumProductId;

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
