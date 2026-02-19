# 📋 تقرير التوافق بين التطبيقات و Firestore Rules

## ✅ الـ Models متوافقة

### Driver User Model (`driver_users` collection)
| Field | الوصف | موجود |
|-------|-------|-------|
| `id` | معرف السائق | ✅ |
| `fullName` | الاسم الكامل | ✅ |
| `email` | البريد الإلكتروني | ✅ |
| `phoneNumber` | رقم الهاتف | ✅ |
| `isOnline` | حالة الاتصال | ✅ |
| `isApproved` | معتمد من الأدمن (بدل isActive) | ✅ |
| `documentVerification` | الوثائق موثقة (بدل isVerified) | ✅ |
| `createdAt` | تاريخ الإنشاء | ✅ |
| `walletAmount` | رصيد المحفظة | ✅ |
| `location` | الموقع الحالي | ✅ |
| `fcmToken` | رمز الإشعارات | ✅ |

### Customer User Model (`users` collection)
| Field | الوصف | موجود |
|-------|-------|-------|
| `id` | معرف العميل | ✅ |
| `fullName` | الاسم الكامل | ✅ |
| `email` | البريد الإلكتروني | ✅ |
| `phoneNumber` | رقم الهاتف | ✅ |
| `isActive` | الحساب نشط | ✅ |
| `createdAt` | تاريخ الإنشاء | ✅ |
| `walletAmount` | رصيد المحفظة | ✅ |

---

## ✅ Collections المضافة

### Customer App (`collection_name.dart`)
```dart
// Collections جديدة مضافة:
- driverLocation      // تتبع موقع السائق
- orderBids           // عروض السائقين (زي inDrive)
- notifications       // الإشعارات
- supportTickets      // تذاكر الدعم
- scheduledRides      // الرحلات المجدولة
- favoriteLocations   // الأماكن المفضلة
- rideHistory         // تاريخ الرحلات
- cmsPages            // صفحات المحتوى
- cancellationReasons // أسباب الإلغاء
```

### Driver App (`collection_name.dart`)
```dart
// Collections جديدة مضافة:
- driverLocation      // موقع السائق
- driverEarnings      // أرباح السائق
- orderBids           // العروض المقدمة
- notifications       // الإشعارات
- supportTickets      // تذاكر الدعم
- scheduledRides      // الرحلات المجدولة
- favoriteLocations   // الأماكن المفضلة
- ordersFreight       // طلبات الشحن
- withdrawalRequests  // طلبات السحب
```

---

## 🔐 Firestore Rules - Field Mapping

الـ Rules محدّثة لتتوافق مع الـ Model الحالي:

| في Rules | في Model | الوظيفة |
|----------|----------|---------|
| `isApproved` | `isApproved` | الأدمن وافق على الحساب |
| `documentVerification` | `documentVerification` | الوثائق متحققة |
| `isOnline` | `isOnline` | السائق متاح للطلبات |

### Helper Function المحدّثة:
```javascript
function isActiveDriver() {
  return isDriver() && 
    get(...).data.isApproved == true &&        // معتمد من الأدمن
    get(...).data.documentVerification == true; // الوثائق موثقة
}
```

---

## ⚠️ ملاحظات مهمة

### 1. السائق لازم يكون:
- ✅ `isApproved = true` (معتمد من الأدمن)
- ✅ `documentVerification = true` (الوثائق موثقة)
- ✅ `isOnline = true` (متصل) - للظهور للعملاء

### 2. الحقول المحمية (الأدمن فقط):
- `isApproved` - السائق مش يقدر يغيره
- `documentVerification` - السائق مش يقدر يغيره
- `walletAmount` - بيتغير من السيستم فقط

### 3. الطلبات:
- العميل يقدر يشوف طلباته
- السائق يقدر يشوف طلباته + الطلبات الجديدة (لو isApproved & documentVerification)
- مفيش حذف للطلبات (audit trail)

---

## 📦 Collections كاملة

### Public Read (متاحة للجميع):
- `settings` - إعدادات التطبيق
- `service` - أنواع الخدمات
- `intercity_service` - خدمات المدن
- `banner` - البنرات الإعلانية
- `tax` - الضرائب
- `currency` - العملات
- `languages` - اللغات
- `zone` - المناطق
- `faq` - الأسئلة الشائعة
- `sos` - أرقام الطوارئ
- `cms_pages` - صفحات المحتوى

### Authenticated Read (المستخدمين المسجلين):
- `users` - بيانات العملاء
- `driver_users` - بيانات السائقين
- `coupon` - الكوبونات

### Owner Only:
- `orders` - الطلبات (العميل + السائق المخصص)
- `wallet_transaction` - معاملات المحفظة
- `chat` - المحادثات
- `notifications` - الإشعارات

---

## 🚀 خطوات التطبيق

1. **انسخ الـ Rules الجديدة:**
   - افتح ملف `firestore_rules_updated.rules`
   - انسخ المحتوى إلى Firebase Console → Firestore → Rules

2. **اعمل Deploy:**
   ```bash
   firebase deploy --only firestore:rules
   ```

3. **تأكد من البيانات في Firebase:**
   - كل سائق لازم يكون عنده:
     - `isApproved: true` (لو معتمد)
     - `documentVerification: true` (لو الوثائق تمام)

---

## ✅ الحالة النهائية

| العنصر | الحالة |
|--------|--------|
| Customer App Models | ✅ متوافق |
| Driver App Models | ✅ متوافق |
| Collection Names | ✅ محدّث |
| Firestore Rules | ✅ محدّث ومتوافق |
| Field Protection | ✅ مفعّل |
