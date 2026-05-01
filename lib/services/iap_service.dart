import 'package:flutter_poolakey/flutter_poolakey.dart';

class IAPService {
  // Replace with actual RSA key from Bazaar panel
  static const String _rsaKey = "MIHNMA0GCSqGSIb3DQEBAQUAA4G7ADCBtwKBrwC9tVp0BzVrRNvZkQJVbM/5OKrFKONPYFk0iuCZc6jXaMznCIxj2YNBhyVEOhWLdlP6csHNCA0z5AH3piffSEBXoLeNB5+iwQl4+SVPbvW1hAbayMG/UJtwIi26q5F6LoA2WicDNvSK91mD9HDTRYiBd8i/jmL/m4Vywfg/okN20hTznm1yXiEm9mz8De6t64yVmdYCBPY5K7W0aCPGLK2grEvTnYGH7YjBTi4RlkECAwEAAQ==";
  static const String premiumProductId = "pooli";

  Future<bool> init() async {
    try {
      bool success = false;
      await FlutterPoolakey.connect(
        _rsaKey,
        onSucceed: () => success = true,
        onFailed: () => success = false,
      );
      return success;
    } catch (e) {
      print("Poolakey connect error: $e");
      return false;
    }
  }

  Future<bool> checkPurchase() async {
    try {
      final purchases = await FlutterPoolakey.getAllPurchasedProducts();
      return purchases.any((p) => p.productId == premiumProductId);
    } catch (e) {
      print("Check purchase error: $e");
      return false;
    }
  }

  Future<bool> purchasePremium() async {
    try {
      final purchaseInfo = await FlutterPoolakey.purchase(
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
