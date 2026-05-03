import 'dart:async';
import 'package:flutter_poolakey/flutter_poolakey.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IAPService {
  // Replace with actual RSA key from Bazaar panel
  static const String _rsaKey = "MIHNMA0GCSqGSIb3DQEBAQUAA4G7ADCBtwKBrwC9tVp0BzVrRNvZkQJVbM/5OKrFKONPYFk0iuCZc6jXaMznCIxj2YNBhyVEOhWLdlP6csHNCA0z5AH3piffSEBXoLeNB5+iwQl4+SVPbvW1hAbayMG/UJtwIi26q5F6LoA2WicDNvSK91mD9HDTRYiBd8i/jmL/m4Vywfg/okN20hTznm1yXiEm9mz8De6t64yVmdYCBPY5K7W0aCPGLK2grEvTnYGH7YjBTi4RlkECAwEAAQ==";
  static const String premiumProductId = "pooli";

  Future<bool> init() async {
    try {
      final completer = Completer<bool>();
      
      await FlutterPoolakey.connect(
        _rsaKey,
        onSucceed: () {
          if (!completer.isCompleted) completer.complete(true);
        },
        onFailed: () {
          if (!completer.isCompleted) completer.complete(false);
        },
      );
      
      return await completer.future;
    } catch (e) {
      print("Poolakey connect error: $e");
      return false;
    }
  }

  Future<bool> checkPurchase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isCachedPremium = prefs.getBool('isPremium') ?? false;
      if (isCachedPremium) return true;

      final purchases = await FlutterPoolakey.getAllPurchasedProducts();
      final isPremium = purchases.any((p) => p.productId == premiumProductId);
      
      if (isPremium) {
        await prefs.setBool('isPremium', true);
      }
      return isPremium;
    } catch (e) {
      print("Check purchase error: $e");
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('isPremium') ?? false;
    }
  }

  Future<bool> purchasePremium() async {
    try {
      final purchaseInfo = await FlutterPoolakey.purchase(
        premiumProductId,
        payload: "premium_upgrade",
      );
      
      final isPremium = purchaseInfo.productId == premiumProductId;
      if (isPremium) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isPremium', true);
      }
      return isPremium;
    } catch (e) {
      print("Purchase error: $e");
      return false;
    }
  }
}
