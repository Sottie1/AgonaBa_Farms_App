class PaystackConfig {
  // Replace with your actual Paystack public key
  static const String publicKey = 'YOUR_PAYSTACK_PUBLIC_KEY';
  
  // Your callback URL for payment verification
  static const String callbackUrl = 'https://yourdomain.com/payment-callback';
  
  // Supported currencies (Paystack supports multiple African currencies)
  static const List<String> supportedCurrencies = [
    'GHS', // Ghanaian Cedi
    'NGN', // Nigerian Naira
    'KES', // Kenyan Shilling
    'UGX', // Ugandan Shilling
    'ZAR', // South African Rand
    'USD', // US Dollar
  ];
  
  // Default currency for your app
  static const String defaultCurrency = 'GHS';
  
  // Payment channels supported by Paystack
  static const List<String> supportedChannels = [
    'card',
    'bank',
    'ussd',
    'qr',
    'mobile_money',
    'bank_transfer',
  ];
}
