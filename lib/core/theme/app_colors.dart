import 'package:flutter/material.dart';

/// لوحة ألوان التطبيق - هوية بصرية عصرية واحترافية
/// اللون الأساسي مستوحى من الطابع الوردي/الأسود لـ SHEIN لكن بلمسة احترافية هادئة
class AppColors {
  const AppColors._();

  // اللون الأساسي (Primary)
  static const Color primary = Color(0xFFE8438A); // وردي عصري
  static const Color primaryDark = Color(0xFFB92C68);
  static const Color primaryLight = Color(0xFFFCE4EF);

  // ألوان ثانوية
  static const Color secondary = Color(0xFF2D3142); // كحلي غامق أنيق
  static const Color accent = Color(0xFF00C9A7); // فيروزي للأرباح/النجاح

  // ألوان الحالات (Status Colors) - لكل حالة طلب لون مميز
  static const Color statusNew = Color(0xFF6C63FF);
  static const Color statusOrdered = Color(0xFFFFA726);
  static const Color statusShipped = Color(0xFF29B6F6);
  static const Color statusArrived = Color(0xFF66BB6A);
  static const Color statusDelivered = Color(0xFF00C9A7);
  static const Color statusCancelled = Color(0xFFEF5350);

  // ألوان دلالية للمبالغ المالية
  static const Color profitColor = Color(0xFF00C9A7); // ربح = أخضر فيروزي
  static const Color purchaseColor = Color(0xFFFF7043); // شراء = برتقالي دافئ
  static const Color sellingColor = Color(0xFF42A5F5); // بيع = أزرق

  static Color statusColor(int statusIndex) {
    switch (statusIndex) {
      case 0:
        return statusNew;
      case 1:
        return statusOrdered;
      case 2:
        return statusShipped;
      case 3:
        return statusArrived;
      case 4:
        return statusDelivered;
      case 5:
        return statusCancelled;
      default:
        return statusNew;
    }
  }
}
