# 📋 DOKUMENTASI FLOW BISNIS & ALUR APLIKASI HOME WORKERS

## 🎯 OVERVIEW SISTEM

Home Workers adalah platform marketplace yang menghubungkan customer dengan worker untuk berbagai layanan rumah tangga. Sistem ini memiliki 3 role utama: Customer, Worker, dan Admin.

---

## 🔄 FLOW BISNIS UTAMA

### 1. REGISTRATION & ONBOARDING FLOW

#### 🔐 Customer Registration Flow

```
1. Welcome Page → Select Role (Customer)
2. Register Customer Page
   - Input: nama, email, password, nomor_telepon
   - Validasi: email unique, password strength
   - Auto-generate: customer_id, created_at
3. Email Verification
   - Send verification email
   - Customer clicks verification link
   - Account status: verified
4. Login & Dashboard Access
```

#### 👷 Worker Registration Flow

```
1. Welcome Page → Select Role (Worker)
2. Register Worker Page
   - Input: nama, email, password, nomor_telepon, keahlian
   - Validasi: email unique, password strength
   - Auto-generate: worker_id, created_at
3. Email Verification
   - Send verification email
   - Worker clicks verification link
   - Account status: verified
4. Document Upload (KTP & Portfolio)
   - Upload KTP (required)
   - Upload portfolio images (optional)
   - Status: pending_approval
5. Admin Approval Process
   - Admin reviews documents
   - Status: approved/rejected
6. Service Creation
   - Worker creates service listings
   - Set pricing, categories, descriptions
7. Ready to Receive Orders
```

### 2. SERVICE DISCOVERY & BOOKING FLOW

#### 🛍️ Customer Service Discovery

```
1. Customer Dashboard
2. Marketplace Page
   - Browse all approved services
   - Filter by: category, price, rating, location
   - Search by service name
3. Service Detail Page
   - View service details, photos, pricing
   - Check worker profile & reviews
   - View availability
4. Booking Decision
```

#### 📅 Booking Process Flow

```
1. Service Detail Page → Book Service
2. Booking Form
   - Select date & time
   - Input address details
   - Add special notes/requirements
   - Choose payment method
3. Payment Processing
   - Fixed Price Services: Pay full amount
   - Survey Services: Pay survey fee first
4. Order Creation
   - Generate order_id
   - Status: pending
   - Send notifications to worker
5. Worker Response
   - Accept: Status → confirmed
   - Reject: Status → cancelled, refund processed
```

### 3. ORDER MANAGEMENT FLOW

#### 📋 Order Lifecycle

```
PENDING → CONFIRMED → IN_PROGRESS → COMPLETED → REVIEWED
    ↓         ↓           ↓            ↓          ↓
 (Worker)  (Worker)   (Worker)    (Customer)  (Customer)
 Response  Starts     Completes   Confirms    Reviews
          Work       Work        Completion
```

#### 🔄 Detailed Order States

**PENDING (Menunggu Konfirmasi)**

- Customer telah membuat booking
- Worker belum merespons
- Timeout: 24 jam (auto-cancel jika tidak direspons)

**CONFIRMED (Dikonfirmasi)**

- Worker menerima pesanan
- Jadwal kerja telah disepakati
- Customer mendapat notifikasi konfirmasi

**IN_PROGRESS (Sedang Dikerjakan)**

- Worker memulai pekerjaan
- Customer dapat melacak progress
- Chat tersedia untuk komunikasi

**COMPLETED (Selesai)**

- Worker menandai pekerjaan selesai
- Customer diminta konfirmasi penyelesaian
- Payment released ke worker (minus platform fee)

**REVIEWED (Telah Direview)**

- Customer memberikan rating & review
- Review tampil di profil worker
- Order cycle complete

### 4. PAYMENT & WALLET FLOW

#### 💰 Payment Processing

```
1. Customer Payment
   - Fixed Services: Full payment upfront
   - Survey Services: Survey fee first, remaining after survey
   - Payment methods: Credit Card, E-wallet, Bank Transfer

2. Escrow System
   - Payment held in platform escrow
   - Released after service completion confirmation
   - Platform fee deducted (10-15%)

3. Worker Wallet
   - Earnings accumulated in wallet
   - Withdrawal requests processed
   - Minimum withdrawal: Rp 50,000
```

#### 🏦 Wallet Management

```
Customer Wallet:
- Top up for future bookings
- Voucher credits
- Refund credits

Worker Wallet:
- Service earnings
- Bonus payments
- Withdrawal history
```

### 5. COMMUNICATION FLOW

#### 💬 Chat System

```
1. Order-based Chat
   - Available after booking confirmation
   - Real-time messaging
   - File sharing (photos, documents)
   - Auto-archived after order completion

2. Pre-booking Inquiry
   - Customer can ask questions before booking
   - Worker can provide quotes/estimates
   - Helps in decision making
```

### 6. REVIEW & RATING FLOW

#### ⭐ Review System

```
1. Post-Service Review
   - Customer reviews worker after completion
   - Rating: 1-5 stars
   - Written feedback (optional)
   - Photo evidence (optional)

2. Review Display
   - Shows on worker profile
   - Affects worker ranking
   - Influences customer decisions

3. Review Moderation
   - Admin can moderate inappropriate reviews
   - Dispute resolution system
```

---

## 🎭 USER JOURNEY MAPPING

### 👤 CUSTOMER JOURNEY

#### First-Time User

```
1. App Download/Website Visit
2. Welcome Screen → "Butuh Jasa Rumah Tangga?"
3. Browse Services (Guest Mode)
4. Register to Book Services
5. Email Verification
6. Complete Profile Setup
7. First Service Booking
8. Payment & Service Experience
9. Review & Repeat Usage
```

#### Returning Customer

```
1. Login
2. Dashboard → Quick Actions
   - Reorder previous services
   - Browse new services
   - Check order status
3. Streamlined Booking Process
4. Loyalty Benefits (Vouchers)
```

### 👷 WORKER JOURNEY

#### New Worker Onboarding

```
1. Registration & Email Verification
2. Document Upload (KTP, Portfolio)
3. Wait for Admin Approval
4. Profile Setup & Service Creation
5. First Order Notification
6. Service Delivery & Payment
7. Build Reputation through Reviews
8. Scale Business (Multiple Services)
```

#### Established Worker

```
1. Daily Login → Check New Orders
2. Manage Schedule & Availability
3. Communicate with Customers
4. Complete Services
5. Manage Earnings & Withdrawals
6. Update Services & Pricing
```

---

## 🔧 TECHNICAL FLOW

### 🏗️ System Architecture Flow

```
Mobile App (Flutter) ↔ API Gateway ↔ Firebase Functions ↔ Firestore DB
                                   ↔ Firebase Storage (Files)
                                   ↔ Firebase Auth (Authentication)
                                   ↔ FCM (Notifications)
                                   ↔ Payment Gateway (Midtrans)
```

### 📱 App Navigation Flow

#### Customer App Navigation

```
Splash → Welcome → Login/Register → Dashboard
                                      ├── Marketplace
                                      ├── My Orders
                                      ├── Chat
                                      ├── Wallet
                                      ├── Profile
                                      └── Notifications
```

#### Worker App Navigation

```
Splash → Welcome → Login/Register → Dashboard
                                      ├── My Services
                                      ├── Orders
                                      ├── Chat
                                      ├── Wallet
                                      ├── Reviews
                                      └── Profile
```

### 🔄 Data Flow Architecture

#### Order Data Flow

```
1. Customer creates booking
   ↓
2. Order document created in Firestore
   ↓
3. Notification sent to worker (FCM)
   ↓
4. Worker responds (accept/reject)
   ↓
5. Order status updated
   ↓
6. Notifications sent to customer
   ↓
7. Real-time updates via Firestore listeners
```

#### Payment Data Flow

```
1. Customer initiates payment
   ↓
2. Payment request to Midtrans
   ↓
3. Payment confirmation webhook
   ↓
4. Update order & wallet balances
   ↓
5. Release payment to worker wallet
   ↓
6. Transaction history updated
```

---

## 🚨 ERROR HANDLING & EDGE CASES

### 🔧 Error Scenarios & Solutions

#### Authentication Errors

```
- Invalid credentials → User-friendly error message
- Email not verified → Redirect to verification page
- Account suspended → Contact admin message
- Network timeout → Retry mechanism
```

#### Booking Errors

```
- Service unavailable → Show alternative services
- Payment failure → Multiple payment options
- Worker cancellation → Auto-refund + rebooking options
- Schedule conflict → Suggest alternative times
```

#### Technical Errors

```
- Network connectivity → Offline mode with sync
- Server errors → Graceful degradation
- File upload failures → Retry mechanism
- Database errors → Fallback responses
```

### 🛡️ Business Logic Safeguards

#### Fraud Prevention

```
- Email verification required
- Document verification for workers
- Payment escrow system
- Review authenticity checks
- Suspicious activity monitoring
```

#### Quality Assurance

```
- Worker approval process
- Service quality monitoring
- Customer feedback system
- Dispute resolution process
- Performance analytics
```

---

## 📊 BUSINESS METRICS & KPIs

### 📈 Key Performance Indicators

#### Customer Metrics

```
- Customer Acquisition Rate
- Customer Retention Rate
- Average Order Value
- Customer Lifetime Value
- Booking Conversion Rate
```

#### Worker Metrics

```
- Worker Onboarding Success Rate
- Worker Retention Rate
- Average Service Rating
- Worker Earnings Growth
- Service Completion Rate
```

#### Platform Metrics

```
- Total Gross Merchandise Value (GMV)
- Platform Revenue (Commission)
- Order Fulfillment Rate
- Customer Satisfaction Score
- Platform Usage Growth
```

### 🎯 Success Metrics

#### Short-term Goals (3-6 months)

```
- 1000+ registered customers
- 500+ verified workers
- 5000+ completed orders
- 4.5+ average rating
- 85%+ order completion rate
```

#### Long-term Goals (1-2 years)

```
- 10,000+ active customers
- 2,000+ active workers
- 50,000+ completed orders
- Multi-city expansion
- Additional service categories
```

---

## 🔮 FUTURE ENHANCEMENTS

### 🚀 Planned Features

#### Phase 2 Features

```
- Advanced scheduling system
- Subscription-based services
- Worker team management
- Customer loyalty program
- Advanced analytics dashboard
```

#### Phase 3 Features

```
- AI-powered service recommendations
- Automated quality scoring
- Multi-language support
- Integration with smart home devices
- Franchise management system
```

### 🌟 Innovation Opportunities

```
- IoT integration for service monitoring
- AR/VR for service previews
- Blockchain for transparent reviews
- Machine learning for demand prediction
- Voice-activated booking system
```

---

## 📞 SUPPORT & MAINTENANCE

### 🛠️ Operational Procedures

#### Daily Operations

```
- Monitor system health
- Process worker applications
- Handle customer support tickets
- Review and moderate content
- Analyze performance metrics
```

#### Weekly Operations

```
- Generate business reports
- Update service categories
- Review worker performance
- Process payments and withdrawals
- Plan marketing campaigns
```

#### Monthly Operations

```
- System performance review
- Feature usage analysis
- Customer satisfaction surveys
- Worker feedback sessions
- Strategic planning meetings
```

---

_Dokumentasi ini akan terus diperbarui seiring dengan perkembangan platform Home Workers._
