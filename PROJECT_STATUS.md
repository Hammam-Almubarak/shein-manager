# حالة مشروع Shein Manager - مكتمل ✅

## ✅ المرحلة 1 - قاعدة البيانات (Drift + SQLite)
## ✅ المرحلة 2 - DAOs + Utils
## ✅ المرحلة 3 - Domain Layer (Entities + Repositories + UseCases)
## ✅ المرحلة 4 - Data Layer (Mappers + Repository Impls)
## ✅ المرحلة 5 - Riverpod Providers
## ✅ المرحلة 6 - Dashboard Screen + Themes
## ✅ المرحلة 7 (خطوة 1) - Customers List Screen
## ✅ المرحلة 7 (خطوة 2) - Customer Form + Customer Profile
## ✅ المرحلة 8 - Orders Screens (List + Form + Details + Add Item Sheet)
## ✅ المرحلة 9 - Statistics Screen (fl_chart)
## ✅ المرحلة 10 - Backup + Export (Excel + PDF)
## ✅ المرحلة 11 - Navigation (go_router + Bottom NavigationBar)

---

## ⚠️ تعليمات البناء المحلي

بعد فك ضغط المشروع وفتحه في VS Code أو Android Studio:

```bash
# 1. تثبيت الاعتماديات
flutter pub get

# 2. توليد ملفات Drift (*.g.dart) - مطلوب للبناء
dart run build_runner build --delete-conflicting-outputs

# 3. تشغيل التطبيق
flutter run
```

## 📁 هيكل الملفات الكامل

```
lib/
├── main.dart                         ← نقطة الدخول (MaterialApp.router)
├── core/
│   ├── constants/
│   │   ├── order_status.dart         ← enum حالات الطلب
│   │   └── orders_sort_by.dart       ← enum خيارات الفرز
│   ├── routing/
│   │   └── app_router.dart           ← go_router + Bottom NavigationBar
│   ├── services/
│   │   ├── backup_service.dart       ← نسخ احتياطي / استعادة
│   │   └── export_service.dart       ← تصدير Excel / PDF
│   ├── theme/
│   │   ├── app_colors.dart           ← لوحة الألوان
│   │   └── app_theme.dart            ← Material 3 Light + Dark
│   └── utils/
│       ├── formatters.dart           ← تنسيق العملة والتاريخ
│       ├── money_utils.dart          ← تقريب مالي
│       └── order_number_generator.dart ← توليد ORD-YYYY-XXXX
├── data/
│   ├── database/
│   │   ├── app_database.dart         ← AppDatabase (Drift)
│   │   ├── daos/                     ← DAOs الأربعة
│   │   └── tables/                   ← جداول Drift الأربعة
│   ├── mappers/                      ← تحويل Row <-> Entity
│   └── repositories/                 ← تنفيذ Repositories
├── domain/
│   ├── entities/                     ← كيانات Dart النقية
│   ├── repositories/                 ← عقود مجردة (interfaces)
│   └── usecases/                     ← منطق الأعمال (11 usecase)
└── presentation/
    ├── providers/                    ← Riverpod providers
    ├── screens/
    │   ├── dashboard/                ← الداشبورد الرئيسي
    │   ├── customers/                ← قائمة + بروفايل + نموذج
    │   ├── orders/                   ← قائمة + تفاصيل + نموذج + إضافة منتج
    │   ├── statistics/               ← 4 رسوم بيانية
    │   ├── backup/                   ← نسخ احتياطي + تصدير
    │   └── search/                   ← بحث شامل
    └── widgets/                      ← مكونات مشتركة
```
