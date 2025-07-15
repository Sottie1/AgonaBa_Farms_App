# Farming Management App

A comprehensive Flutter application for managing farm operations, connecting farmers with customers, and facilitating agricultural commerce.

## 📱 Overview

The Farming Management App is a dual-platform application that serves both farmers and customers. Farmers can manage their products, track orders, and analyze farm performance, while customers can browse products, place orders, and track their purchases.

## 🚀 Features

### For Farmers
- **Product Management**: Add, edit, and delete farm products with images
- **Order Management**: View and manage incoming orders
- **Analytics Dashboard**: Track sales, revenue, and farm performance
- **Category Management**: Organize products by categories
- **Profile Management**: Update farm and personal information
- **Real-time Notifications**: Get notified of new orders and updates

### For Customers
- **Product Browsing**: Browse products with infinite scrolling and category filters
- **Search Functionality**: Search products by name or description
- **Shopping Cart**: Add products to cart and manage quantities
- **Order Placement**: Complete checkout process
- **Order Tracking**: View order history and status
- **Offline Support**: Browse products even without internet connection
- **Real-time Notifications**: Get updates on orders and promotions

## 🛠 Technology Stack

- **Framework**: Flutter 3.6.1+
- **Backend**: Firebase
  - **Authentication**: Firebase Auth
  - **Database**: Cloud Firestore
  - **Storage**: Firebase Storage
  - **Messaging**: Firebase Cloud Messaging
- **State Management**: Provider
- **Image Handling**: Cached Network Image, Image Picker
- **Connectivity**: Internet Connection Checker
- **UI Components**: Carousel Slider, Shimmer, Syncfusion Charts

## 📁 Project Structure

```
farming_management/
├── lib/
│   ├── auth/                    # Authentication related files
│   │   ├── auth_service.dart    # Firebase auth service
│   │   ├── login_screen.dart    # Login UI
│   │   ├── register_screen.dart # Registration UI
│   │   └── forgot_password.dart # Password recovery
│   ├── models/                  # Data models
│   │   ├── user_model.dart      # User data model
│   │   ├── product_model.dart   # Product data model
│   │   ├── order_model.dart     # Order data model
│   │   ├── cart_item.dart       # Cart item model
│   │   ├── category_model.dart  # Category model
│   │   ├── review_model.dart    # Review model
│   │   └── notification_model.dart # Notification model
│   ├── screens/                 # UI screens
│   │   ├── customer/            # Customer-specific screens
│   │   │   ├── customer_products.dart # Main product browsing
│   │   │   ├── product_detail_screen.dart # Product details
│   │   │   ├── cart_screen.dart # Shopping cart
│   │   │   ├── checkout_screen.dart # Checkout process
│   │   │   ├── customer_orders.dart # Order history
│   │   │   ├── customer_profile.dart # Customer profile
│   │   │   └── customer_notifications.dart # Notifications
│   │   ├── farmer/              # Farmer-specific screens
│   │   │   ├── farmer_dashboard.dart # Main dashboard
│   │   │   ├── product_management.dart # Product management
│   │   │   ├── order_management.dart # Order management
│   │   │   ├── farm_analytics.dart # Analytics dashboard
│   │   │   └── farmer_profile.dart # Farmer profile
│   │   ├── onboarding_screen.dart # App introduction
│   │   ├── splash_screen.dart   # Loading screen
│   │   └── home_screen.dart     # Main home screen
│   ├── services/                # Business logic services
│   │   ├── cart_service.dart    # Shopping cart management
│   │   ├── product_service.dart # Product operations
│   │   ├── image_service.dart   # Image handling
│   │   ├── notification_service.dart # Push notifications
│   │   └── connectivity_service.dart # Network connectivity
│   ├── widgets/                 # Reusable UI components
│   │   ├── product_card.dart    # Product display card
│   │   ├── product_grid.dart    # Product grid layout
│   │   ├── quantity_selector.dart # Quantity selection
│   │   ├── offline_banner.dart  # Offline status indicator
│   │   └── offline_retry_widget.dart # Retry functionality
│   └── main.dart               # App entry point
├── assets/                     # Static assets
│   ├── farm_logo.png          # App logo
│   ├── onboarding*.jpg        # Onboarding images
│   └── promo_banners/         # Promotional banners
├── android/                   # Android-specific files
├── ios/                      # iOS-specific files
└── pubspec.yaml              # Dependencies and configuration
```

## 🔧 Installation & Setup

### Prerequisites
- Flutter SDK 3.6.1 or higher
- Dart SDK
- Android Studio / VS Code
- Firebase project setup

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd farming_management
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a Firebase project
   - Enable Authentication, Firestore, Storage, and Cloud Messaging
   - Download and add configuration files:
     - `google-services.json` for Android
     - `GoogleService-Info.plist` for iOS

4. **Run the application**
   ```bash
   flutter run
   ```

## 🔐 Authentication System

The app uses Firebase Authentication with the following features:

- **Email/Password Authentication**: Standard login and registration
- **User Types**: Separate flows for farmers and customers
- **Password Recovery**: Forgot password functionality
- **Session Management**: Automatic login state persistence
- **First-time User Detection**: Onboarding flow for new users

### User Types
- **Farmer**: Can manage products, view orders, and access analytics
- **Customer**: Can browse products, place orders, and manage profile




## 🔄 State Management

The app uses the Provider pattern for state management with the following providers:

- **AuthService**: Manages user authentication state
- **CartService**: Manages shopping cart state
- **NotificationService**: Handles push notifications
- **ConnectivityService**: Monitors network connectivity
- **ImageService**: Handles image operations

## 🌐 Offline Support

The app includes comprehensive offline support:

- **Connectivity Monitoring**: Real-time internet connection detection
- **Offline Banner**: Visual indicator when offline
- **Retry Mechanism**: Automatic retry for failed network requests
- **Cached Images**: Product images cached for offline viewing
- **Graceful Degradation**: App remains functional with limited features



## 🔔 Push Notifications

The app supports push notifications for:
- New order notifications (farmers)
- Order status updates (customers)
- Promotional messages
- System announcements

## 📈 Analytics & Reporting

### Farmer Analytics
- Sales performance tracking
- Revenue analysis
- Product popularity metrics
- Order fulfillment statistics
- Customer feedback analysis

### Charts and Visualizations
- Line charts for sales trends
- Bar charts for product performance
- Pie charts for category distribution
- Real-time data updates

## 🛡️ Security Features

- **Firebase Security Rules**: Database access control
- **Input Validation**: Client-side and server-side validation
- **Image Upload Security**: Secure file upload with validation
- **Authentication Tokens**: Secure session management
- **Data Encryption**: Sensitive data encryption

