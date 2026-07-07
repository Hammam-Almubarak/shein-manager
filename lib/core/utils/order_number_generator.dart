/// يولّد رقم طلب فريد بصيغة: ORD-YYYY-XXXX
/// مثال: ORD-2026-0001, ORD-2026-0002 ...
/// الرقم التسلسلي (seq) يُمرَّر من الطبقة التي تعرف عدد طلبات السنة الحالية
/// (يُحسب داخل OrdersDao عبر عدّ الطلبات ضمن نفس السنة + 1)
class OrderNumberGenerator {
  const OrderNumberGenerator._();

  static String generate({required int year, required int seq}) {
    final paddedSeq = seq.toString().padLeft(4, '0');
    return 'ORD-$year-$paddedSeq';
  }
}
