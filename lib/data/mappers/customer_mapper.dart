import '../database/app_database.dart' show CustomerRow;
import '../../domain/entities/customer.dart';

/// يحوّل بين صف قاعدة البيانات (CustomerRow) وكيان الـ Domain (Customer)
/// هذا الفصل مهم: لو غيّرنا مكتبة قاعدة البيانات مستقبلًا، الـ Domain ما بيتأثر إطلاقًا
extension CustomerRowMapper on CustomerRow {
  Customer toEntity() {
    return Customer(
      id: id,
      fullName: fullName,
      phoneNumber: phoneNumber,
      notes: notes,
      createdAt: createdAt,
    );
  }
}
