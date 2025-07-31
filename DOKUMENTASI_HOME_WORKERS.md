# 📋 DOKUMENTASI LENGKAP HOME WORKERS

## 📖 Daftar Isi

1. [Overview Sistem](#overview-sistem)
2. [Arsitektur Aplikasi](#arsitektur-aplikasi)
3. [Backend Documentation](#backend-documentation)
4. [Frontend Documentation](#frontend-documentation)
5. [API Endpoints](#api-endpoints)
6. [Database Schema](#database-schema)
7. [Fitur-Fitur Utama](#fitur-fitur-utama)
8. [Setup & Installation](#setup--installation)
9. [Testing Guide](#testing-guide)
10. [Deployment Guide](#deployment-guide)

---

## 🏠 Overview Sistem

**Home Workers** adalah platform marketplace yang menghubungkan customer dengan worker untuk berbagai layanan rumah tangga seperti cleaning service, perbaikan, dan maintenance.

### 🎯 Tujuan Aplikasi

- Memudahkan customer mencari dan memesan layanan rumah tangga
- Memberikan platform bagi worker untuk menawarkan jasa mereka
- Menyediakan sistem pembayaran yang aman dan terpercaya
- Memfasilitasi komunikasi antara customer dan worker

### 👥 User Roles

1. **Customer**: Pengguna yang membutuhkan layanan
2. **Worker**: Penyedia layanan
3. **Admin**: Pengelola platform

---

## 🏗️ Arsitektur Aplikasi

### Tech Stack

**Backend:**

- Node.js + Express.js
- Firebase Functions (Serverless)
- Firebase Firestore (Database)
- Firebase Storage (File Storage)
- Firebase Authentication

**Frontend:**

- Flutter (Dart)
- Provider (State Management)
- HTTP Package (API Calls)

**Payment Gateway:**

- Midtrans

**Third-Party Services:**

- Firebase Cloud Messaging (Push Notifications)
- Google Maps API (Location Services)

---

## 🔧 Backend Documentation

### 📁 Struktur Folder Backend

```
home-workers-be/
├── functions/
│   ├── src/
│   │   ├── config/
│   │   │   ├── env.js
│   │   │   └── midtrans.js
│   │   ├── controllers/
│   │   │   ├── adminController.js
│   │   │   ├── authController.js
│   │   │   ├── chatController.js
│   │   │   ├── dashboardController.js
│   │   │   ├── midtransController.js
│   │   │   ├── orderController.js
│   │   │   ├── paymentController.js
│   │   │   ├── reviewController.js
│   │   │   ├── serviceController.js
│   │   │   ├── userController.js
│   │   │   ├── vouchersController.js
│   │   │   ├── walletController.js
│   │   │   └── workerController.js
│   │   ├── middlewares/
│   │   │   ├── authMiddleware.js
│   │   │   ├── busboyupload.js
│   │   │   └── uploadMiddleware.js
│   │   ├── routes/
│   │   │   ├── adminRoutes.js
│   │   │   ├── authRoutes.js
│   │   │   ├── chatRoutes.js
│   │   │   ├── dashboardRoutes.js
│   │   │   ├── midtransRoutes.js
│   │   │   ├── notificationRoutes.js
│   │   │   ├── orderRoutes.js
│   │   │   ├── paymentRoutes.js
│   │   │   ├── reviewRoutes.js
│   │   │   ├── serviceRoutes.js
│   │   │   ├── userRoutes.js
│   │   │   ├── vouchersRoutes.js
│   │   │   ├── walletRoutes.js
│   │   │   └── workerRoutes.js
│   │   ├── utils/
│   │   │   ├── emailService.js
│   │   │   ├── responseHelper.js
│   │   │   └── uploadToFirebase.js
│   │   └── index.js
│   ├── package.json
│   └── uploads/
├── firebase.json
└── .firebaserc
```

### 🔐 Authentication System

- Firebase Authentication untuk login/register
- JWT Token untuk API authorization
- Role-based access control (Customer, Worker, Admin)

### 📊 Controllers Overview

#### AuthController

- `POST /auth/register/customer` - Register customer
- `POST /auth/register/worker` - Register worker
- `POST /auth/login` - Login user
- `GET /auth/me` - Get current user profile
- `POST /auth/forgot-password` - Reset password
- `POST /auth/resend-verification` - Resend email verification

#### UserController

- `PUT /users/me` - Update profile
- `POST /users/me/avatar` - Upload avatar
- `POST /users/me/documents` - Upload documents (KTP, Portfolio)
- `GET /users/me/addresses` - Get user addresses
- `POST /users/me/addresses` - Add new address
- `GET /users/me/notifications` - Get notifications

#### ServiceController

- `GET /services` - Get all approved services
- `POST /services` - Create new service
- `GET /services/my-services` - Get worker's services
- `PUT /services/:id` - Update service
- `DELETE /services/:id` - Delete service

#### OrderController

- `GET /orders/my-orders` - Get user orders
- `POST /orders/:id/accept` - Accept order (worker)
- `PUT /orders/:id/reject` - Reject order (worker)
- `POST /orders/:id/quote` - Propose quote (worker)
- `PUT /orders/:id/quote/respond` - Respond to quote (customer)

#### WalletController

- `GET /wallet/me` - Get wallet balance
- `POST /wallet/me/withdraw` - Request withdrawal

#### ReviewController

- `POST /reviews/orders/:orderId` - Submit review
- `GET /reviews/worker` - Get worker reviews

#### VouchersController

- `GET /vouchers/` - Get available vouchers
- `POST /vouchers/claim` - Claim voucher
- `POST /vouchers/validate` - Validate voucher

---

## 📱 Frontend Documentation

### 📁 Struktur Folder Frontend

```
home_workers_fe/
├── lib/
│   ├── core/
│   │   ├── api/
│   │   │   └── api_service.dart
│   │   ├── models/
│   │   │   ├── address_model.dart
│   │   │   ├── chat_model.dart
│   │   │   ├── message_model.dart
│   │   │   ├── notification_model.dart
│   │   │   ├── order_model.dart
│   │   │   ├── service_model.dart
│   │   │   ├── user_model.dart
│   │   │   ├── wallet_model.dart
│   │   │   └── worker_model.dart
│   │   └── state/
│   │       └── auth_provider.dart
│   ├── features/
│   │   ├── auth/
│   │   ├── costumer_flow/
│   │   │   └── vouchers/
│   │   │       └── pages/
│   │   │           └── available_vouchers_page.dart
│   │   ├── notifications/
│   │   ├── profile/
│   │   │   └── pages/
│   │   │       ├── address_management_page.dart
│   │   │       ├── edit_profile_page.dart
│   │   │       └── upload_avatar_page.dart
│   │   ├── worker_flow/
│   │   │   └── reviews/
│   │   │       └── pages/
│   │   │           └── worker_reviews_page.dart
│   │   └── workerprofile/
│   │       └── pages/
│   │           └── upload_documents_page.dart
│   ├── shared_widgets/
│   ├── firebase_options.dart
│   └── main.dart
├── assets/
├── android/
├── ios/
└── pubspec.yaml
```

### 🎨 UI/UX Design System

#### Color Palette

- **Primary Color**: `#1A374D` (Dark Blue)
- **Secondary Color**: `#D9D9D9` (Light Gray)
- **Background**: `#F8F9FA` (Light Background)
- **White**: `#FFFFFF`
- **Success**: `#4CAF50`
- **Error**: `#F44336`
- **Warning**: `#FF9800`

#### Typography

- **Heading**: Bold, 18-24px
- **Body**: Regular, 14-16px
- **Caption**: Regular, 12px

---

## 🔌 API Endpoints

### Authentication Endpoints

```
POST /api/auth/register/customer
POST /api/auth/register/worker
POST /api/auth/login
GET /api/auth/me
POST /api/auth/forgot-password
POST /api/auth/resend-verification
POST /api/auth/user/update-fcm-token
```

### User Management Endpoints

```
PUT /api/users/me
POST /api/users/me/avatar
POST /api/users/me/documents
GET /api/users/me/addresses
POST /api/users/me/addresses
GET /api/users/me/notifications
```

### Service Management Endpoints

```
GET /api/services
POST /api/services
GET /api/services/my-services
GET /api/services/:id
PUT /api/services/:id
DELETE /api/services/:id
POST /api/services/:id/photos
GET /api/services/category/:category
GET /api/services/search
```

### Order Management Endpoints

```
GET /api/orders/my-orders
GET /api/orders/:id
PUT /api/orders/:id/accept
PUT /api/orders/:id/reject
POST /api/orders/:id/quote
PUT /api/orders/:id/quote/respond
PATCH /api/orders/:id/status
GET /api/orders/booked-slots
```

### Payment Endpoints

```
POST /api/payments/initiate
POST /api/payments/start/:orderId
GET /api/payments/status/:orderId
```

### Wallet Endpoints

```
GET /api/wallet/me
POST /api/wallet/me/withdraw
```

### Review Endpoints

```
POST /api/reviews/orders/:orderId
GET /api/reviews/worker
GET /api/reviews/for-worker/me
```

### Voucher Endpoints

```
GET /api/vouchers/
POST /api/vouchers/claim
POST /api/vouchers/validate
```

### Chat Endpoints

```
GET /api/chats
POST /api/chats
GET /api/chats/:id/messages
POST /api/chats/:id/messages
POST /api/chats/:id/read
```

### Dashboard Endpoints

```
GET /api/workers/dashboard/summary
GET /api/dashboard/customer-summary
```

---

## 🗄️ Database Schema

### Collections Structure (Firestore)

#### Users Collection

```javascript
{
  uid: "string",
  email: "string",
  nama: "string",
  role: "CUSTOMER" | "WORKER" | "ADMIN",
  contact: "string",
  avatarUrl: "string",
  gender: "string",
  fcmToken: "string",
  emailVerified: boolean,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### Workers Collection

```javascript
{
  uid: "string", // same as users uid
  keahlian: ["string"],
  deskripsi: "string",
  linkPortofolio: "string",
  noKtp: "string",
  ktpUrl: "string",
  fotoDiriUrl: "string",
  portfolioUrl: "string",
  status: "PENDING" | "APPROVED" | "REJECTED",
  rating: number,
  totalReviews: number,
  createdAt: timestamp
}
```

#### Services Collection

```javascript
{
  id: "string",
  workerId: "string",
  nama: "string",
  kategori: "string",
  deskripsi: "string",
  harga: number,
  photos: ["string"],
  status: "PENDING" | "APPROVED" | "REJECTED",
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### Orders Collection

```javascript
{
  id: "string",
  customerId: "string",
  workerId: "string",
  serviceId: "string",
  status: "PENDING" | "ACCEPTED" | "IN_PROGRESS" | "COMPLETED" | "CANCELLED",
  jadwalPerbaikan: timestamp,
  catatan: "string",
  totalHarga: number,
  proposedPrice: number,
  quoteStatus: "NONE" | "PROPOSED" | "ACCEPTED" | "REJECTED",
  paymentStatus: "PENDING" | "PAID" | "FAILED",
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### Reviews Collection

```javascript
{
  id: "string",
  orderId: "string",
  customerId: "string",
  workerId: "string",
  rating: number,
  comment: "string",
  createdAt: timestamp
}
```

#### Wallets Collection

```javascript
{
  uid: "string", // worker uid
  balance: number,
  totalEarnings: number,
  pendingWithdrawals: number,
  transactions: [
    {
      id: "string",
      type: "EARNING" | "WITHDRAWAL",
      amount: number,
      description: "string",
      status: "PENDING" | "COMPLETED" | "FAILED",
      createdAt: timestamp
    }
  ]
}
```

#### Vouchers Collection

```javascript
{
  id: "string",
  code: "string",
  discountType: "PERCENT" | "FIXED",
  value: number,
  maxDiscount: number,
  minOrder: number,
  maxUsage: number,
  currentUsage: number,
  startDate: timestamp,
  endDate: timestamp,
  isActive: boolean,
  createdAt: timestamp
}
```

#### User Addresses Subcollection

```javascript
users/{uid}/addresses/{addressId}
{
  id: "string",
  label: "string",
  fullAddress: "string",
  location: GeoPoint,
  createdAt: timestamp
}
```

#### User Notifications Subcollection

```javascript
users/{uid}/notifications/{notificationId}
{
  id: "string",
  title: "string",
  body: "string",
  type: "ORDER" | "PAYMENT" | "GENERAL",
  isRead: boolean,
  data: object,
  timestamp: timestamp
}
```

---

## ⭐ Fitur-Fitur Utama

### 🔐 Authentication & Authorization

- [x] Register Customer/Worker
- [x] Login/Logout
- [x] Email Verification
- [x] Password Reset
- [x] Profile Management
- [x] Role-based Access Control

### 👤 User Management

- [x] Profile Update
- [x] Avatar Upload
- [x] Address Management
- [x] Document Upload (Worker)
- [x] Notification System

### 🛠️ Service Management

- [x] Create/Edit/Delete Services
- [x] Service Categories
- [x] Service Photos
- [x] Service Search & Filter
- [x] Service Approval (Admin)

### 📋 Order Management

- [x] Create Order
- [x] Order Status Tracking
- [x] Quote System
- [x] Order History
- [x] Order Cancellation

### 💳 Payment System

- [x] Midtrans Integration
- [x] Multiple Payment Methods
- [x] Payment Status Tracking
- [x] Voucher System
- [x] Wallet System (Worker)

### 💬 Communication

- [x] Real-time Chat
- [x] Push Notifications
- [x] Email Notifications

### ⭐ Review System

- [x] Customer Reviews
- [x] Rating System
- [x] Review Display
- [x] Worker Review Management

### 🎫 Voucher System

- [x] Voucher Creation (Admin)
- [x] Voucher Claiming
- [x] Voucher Validation
- [x] Discount Calculation

### 💰 Wallet System

- [x] Earnings Tracking
- [x] Withdrawal Requests
- [x] Transaction History
- [x] Balance Management

---

## 🚀 Setup & Installation

### Prerequisites

- Node.js (v14 or higher)
- Flutter SDK (v3.0 or higher)
- Firebase CLI
- Android Studio / Xcode
- Git

### Backend Setup

1. **Clone Repository**

```bash
git clone <repository-url>
cd home-workers-be
```

2. **Install Dependencies**

```bash
cd functions
npm install
```

3. **Firebase Configuration**

```bash
firebase login
firebase use <your-project-id>
```

4. **Environment Variables**
   Create `functions/src/config/env.js`:

```javascript
module.exports = {
  midtrans: {
    serverKey: "your-midtrans-server-key",
    clientKey: "your-midtrans-client-key",
    isProduction: false,
  },
  firebase: {
    storageBucket: "your-storage-bucket",
  },
};
```

5. **Deploy Functions**

```bash
firebase deploy --only functions
```

### Frontend Setup

1. **Navigate to Frontend Directory**

```bash
cd home_workers_fe
```

2. **Install Dependencies**

```bash
flutter pub get
```

3. **Firebase Configuration**

```bash
flutterfire configure
```

4. **Update API Base URL**
   Update `lib/core/api/api_service.dart`:

```dart
final String _baseUrl = 'https://your-firebase-functions-url/api';
```

5. **Run Application**

```bash
flutter run
```

### Android Setup

1. Add `google-services.json` to `android/app/`
2. Update `android/app/build.gradle` with Firebase dependencies

### iOS Setup

1. Add `GoogleService-Info.plist` to `ios/Runner/`
2. Update `ios/Runner/Info.plist` with required permissions

---

## 🧪 Testing Guide

### Backend Testing

#### Unit Testing

```bash
cd functions
npm test
```

#### API Testing dengan Postman/Curl

**Test Authentication:**

```bash
# Register Customer
curl -X POST https://your-api-url/api/auth/register/customer \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "nama": "Test User"
  }'

# Login
curl -X POST https://your-api-url/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

**Test File Upload:**

```bash
# Upload Avatar
curl -X POST https://your-api-url/api/users/me/avatar \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "avatar=@/path/to/image.jpg"
```

### Frontend Testing

#### Widget Testing

```bash
flutter test
```

#### Integration Testing

```bash
flutter drive --target=test_driver/app.dart
```

### Manual Testing Checklist

#### Authentication Flow

- [ ] Register as Customer
- [ ] Register as Worker
- [ ] Login/Logout
- [ ] Password Reset
- [ ] Email Verification

#### Profile Management

- [ ] Update Profile
- [ ] Upload Avatar
- [ ] Add/Edit/Delete Address
- [ ] Upload Documents (Worker)

#### Service Management

- [ ] Create Service
- [ ] Edit Service
- [ ] Delete Service
- [ ] View Service Details

#### Order Flow

- [ ] Create Order
- [ ] Accept/Reject Order
- [ ] Propose Quote
- [ ] Complete Order
- [ ] Cancel Order

#### Payment Flow

- [ ] Process Payment
- [ ] Apply Voucher
- [ ] Check Payment Status

#### Communication

- [ ] Send/Receive Messages
- [ ] Push Notifications
- [ ] Email Notifications

---

## 🚀 Deployment Guide

### Backend Deployment (Firebase Functions)

1. **Production Environment Setup**

```bash
firebase use production-project-id
```

2. **Set Environment Variables**

```bash
firebase functions:config:set midtrans.server_key="prod-server-key"
firebase functions:config:set midtrans.client_key="prod-client-key"
firebase functions:config:set midtrans.is_production="true"
```

3. **Deploy Functions**

```bash
firebase deploy --only functions
```

4. **Set up Custom Domain (Optional)**

```bash
firebase hosting:channel:deploy production
```

### Frontend Deployment

#### Android Deployment

1. **Generate Keystore**

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. **Configure Signing**
   Create `android/key.properties`:

```
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=upload
storeFile=../upload-keystore.jks
```

3. **Build APK/AAB**

```bash
flutter build apk --release
flutter build appbundle --release
```

4. **Upload to Play Store**

- Upload AAB file to Google Play Console
- Complete store listing
- Submit for review

#### iOS Deployment

1. **Configure Xcode Project**

```bash
open ios/Runner.xcworkspace
```

2. **Set up Certificates & Provisioning Profiles**

- Developer Certificate
- Distribution Certificate
- App Store Provisioning Profile

3. **Build for Release**

```bash
flutter build ios --release
```

4. **Archive and Upload**

- Archive in Xcode
- Upload to App Store Connect
- Submit for review

### Database Security Rules

**Firestore Rules:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /addresses/{addressId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      match /notifications/{notificationId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Workers can access their own worker data
    match /workers/{workerId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == workerId;
    }

    // Services are publicly readable, workers can manage their own
    match /services/{serviceId} {
      allow read: if true;
      allow write: if request.auth != null &&
        request.auth.uid == resource.data.workerId;
    }

    // Orders can be accessed by customer and worker involved
    match /orders/{orderId} {
      allow read, write: if request.auth != null &&
        (request.auth.uid == resource.data.customerId ||
         request.auth.uid == resource.data.workerId);
    }

    // Reviews are publicly readable
    match /reviews/{reviewId} {
      allow read: if true;
      allow write: if request.auth != null &&
        request.auth.uid == resource.data.customerId;
    }

    // Wallets can only be accessed by the owner
    match /wallets/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**Storage Rules:**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /avatars/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /documents/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /services/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

---

## 📊 Monitoring & Analytics

### Firebase Analytics

- User engagement tracking
- Feature usage analytics
- Crash reporting
- Performance monitoring

### Custom Metrics

- Order completion rate
- User retention
- Revenue tracking
- Service popularity

### Error Monitoring

- Crashlytics integration
- Error logging
- Performance alerts

---

## 🔒 Security Best Practices

### Authentication Security

- Strong password requirements
- Email verification mandatory
- JWT token expiration
- Rate limiting on auth endpoints

### Data Security

- Input validation and sanitization
- SQL injection prevention
- XSS protection
- CSRF protection

### File Upload Security

- File type validation
- File size limits
- Virus scanning
- Secure file storage

### API Security

- Authentication required for sensitive endpoints
- Role-based access control
- Request rate limiting
- Input validation

---

## 🐛 Troubleshooting

### Common Issues

#### Backend Issues

1. **Firebase Functions Timeout**

   - Increase timeout in firebase.json
   - Optimize database queries
   - Use pagination for large datasets

2. **CORS Issues**

   - Configure CORS in Express
   - Check allowed origins

3. **File Upload Failures**
   - Check file size limits
   - Verify Firebase Storage permissions
   - Validate file types

#### Frontend Issues

1. **Build Failures**

   - Clear Flutter cache: `flutter clean`
   - Update dependencies: `flutter pub get`
   - Check Dart/Flutter versions

2. **API Connection Issues**

   - Verify API base URL
   - Check network permissions
   - Validate authentication tokens

3. **Push Notification Issues**
   - Verify FCM configuration
   - Check device permissions
   - Test on physical devices

---

## 📈 Future Enhancements

### Planned Features

- [ ] Real-time location tracking
- [ ] Video call integration
- [ ] Advanced search filters
- [ ] Multi-language support
- [ ] Dark mode theme
- [ ] Offline mode support
- [ ] Advanced analytics dashboard
- [ ] Subscription plans
- [ ] Loyalty program
- [ ] Social media integration

### Technical Improvements

- [ ] GraphQL API implementation
- [ ] Microservices architecture
- [ ] Redis caching
- [ ] CDN integration
- [ ] Advanced monitoring
- [ ] Automated testing pipeline
- [ ] Performance optimization

---

## 👥 Team & Contributors

### Development Team

- **Backend Developer**: [Name]
- **Frontend Developer**: [Name]
- **UI/UX Designer**: [Name]
- **Project Manager**: [Name]

### Contact Information

- **Email**: support@homeworkers.com
- **Website**: https://homeworkers.com
- **Documentation**: https://docs.homeworkers.com

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📝 Changelog

### Version 1.0.0 (Current)

- Initial release
- Basic authentication system
- Service management
- Order processing
- Payment integration
- Chat system
- Review system
- Wallet system
- Voucher system

### Version 1.1.0 (Planned)

- Enhanced file upload system
- Improved UI/UX
- Advanced search features
- Performance optimizations

---

_Dokumentasi ini akan terus diperbarui seiring dengan perkembangan aplikasi Home Workers._
