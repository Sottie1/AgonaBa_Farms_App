# Farming Management

A modern, cross-platform farming management application built with Flutter. This app helps farmers and customers manage products, orders, analytics, and notifications efficiently, leveraging Firebase for backend services.

## Features

- **User Authentication**: Secure login, registration, and password recovery using Firebase Auth.
- **Role-based Dashboards**: Separate interfaces for farmers and customers.
- **Product Management**: Farmers can add, edit, and manage products.
- **Order Management**: Customers can place orders; farmers can view and manage them.
- **Notifications**: Real-time notifications for orders and updates.
- **Analytics**: Visualize farm data with charts and analytics.
- **Image Uploads**: Product images with compression and storage via Firebase Storage.
- **Offline Support**: Uses local storage for improved reliability.
- **Beautiful UI**: Modern, responsive design with onboarding screens and promo banners.

## Screenshots

<!-- Add screenshots here if available -->
<!-- ![Screenshot](assets/onboarding1.jpg) -->

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>=3.6.1)
- [Dart SDK](https://dart.dev/get-dart)
- Firebase project (with Android/iOS/Web setup)
- Android Studio, Xcode, or Visual Studio Code

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/farming_management.git
   cd farming_management
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   - Add your `google-services.json` to `android/app/`.
   - Add your `GoogleService-Info.plist` to `ios/Runner/`.
   - Set up Firebase for web if needed.

4. **Run the app:**
   ```bash
   flutter run
   ```

### Project Structure

- `lib/` - Main Dart source code
  - `auth/` - Authentication screens and logic
  - `data/` - Static and onboarding data
  - `models/` - Data models (Product, Order, User, etc.)
  - `screens/` - UI screens for customers and farmers
  - `services/` - Business logic and Firebase integration
  - `widgets/` - Reusable UI components
- `assets/` - Images and promo banners
- `android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/` - Platform-specific code

### Key Dependencies

- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`
- `provider` for state management
- `shared_preferences` for local storage
- `flutter_local_notifications` for push notifications
- `syncfusion_flutter_charts` for analytics
- `image_picker`, `flutter_image_compress` for image handling

See [`pubspec.yaml`](pubspec.yaml) for the full list.

## Contributing

Contributions are welcome! Please open issues and submit pull requests for new features, bug fixes, or improvements.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- [Syncfusion Flutter Charts](https://pub.dev/packages/syncfusion_flutter_charts)

---

Let me know if you want to add more sections (e.g., FAQ, Troubleshooting, Contact) or want a more detailed usage guide!
