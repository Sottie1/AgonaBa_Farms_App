import 'dart:developer';

class PaystackService {
  static final PaystackService _instance = PaystackService._internal();
  factory PaystackService() => _instance;
  PaystackService._internal();

  String _publicKey = "";
  String _accessCode = "";
  String _reference = "";

  // Initialize with public key (simplified)
  Future<bool> initialize(String publicKey) async {
    try {
      log("🔧 Initializing Paystack service...");
      log("🔑 Public Key: ${publicKey.substring(0, 10)}...");

      _publicKey = publicKey;
      log("✅ Paystack service initialized successfully");
      return true;
    } catch (e) {
      log("❌ Error initializing service: $e");
      return false;
    }
  }

  // Launch payment (simplified mock)
  Future<Map<String, dynamic>> launch(String accessCode) async {
    try {
      _accessCode = accessCode;
      log("🚀 Launching payment with access code: $accessCode");

      // Mock successful payment response
      _reference = "ref_${DateTime.now().millisecondsSinceEpoch}";

      return {
        'status': 'success',
        'reference': _reference,
        'message': 'Payment completed successfully (Mock)'
      };
    } catch (e) {
      log("❌ Error launching payment: $e");
      return {'status': 'error', 'message': 'Payment failed: $e'};
    }
  }

  // Simple payment initialization (works reliably)
  static Future<void> initializePayment({
    required String amount,
    required String email,
    required String reference,
    required String callbackUrl,
    required Function(String) onSuccess,
    required Function(String) onError,
    required Function() onCancel,
  }) async {
    try {
      final paystack = PaystackService();

      log("🔄 Initializing Paystack service...");
      final initialized = await paystack
          .initialize("pk_test_c2bca2280c1d6d2f5b4ace25c0621e1e61181141");

      if (!initialized) {
        onError('Failed to initialize Paystack service');
        return;
      }

      log("🔄 Creating mock transaction...");
      final accessCode = "demo_${DateTime.now().millisecondsSinceEpoch}";

      log("🚀 Launching payment...");
      final result = await paystack.launch(accessCode);

      if (result['status'] == "success") {
        onSuccess(result['reference'] ?? reference);
      } else if (result['status'] == "cancelled") {
        onCancel();
      } else {
        onError(result['message'] ?? 'Payment failed');
      }
    } catch (e) {
      log("❌ Payment error: $e");
      onError('Payment failed: $e');
    }
  }

  // Getters
  String get reference => _reference;
  String get accessCode => _accessCode;
  String get publicKey => _publicKey;

  // Verify payment with reference
  static Future<bool> verifyPayment(String reference) async {
    try {
      log("✅ Mock verification successful for reference: $reference");
      return true;
    } catch (e) {
      log('❌ Payment verification failed: $e');
      return false;
    }
  }

  // Get available payment methods
  static List<String> getAvailablePaymentMethods() {
    return [
      'Card',
      'Mobile Money',
      'Bank Transfer',
      'USSD',
    ];
  }
}
