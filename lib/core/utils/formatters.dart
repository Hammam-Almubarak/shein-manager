import 'package:intl/intl.dart';

/// أدوات تنسيق موحّدة لعرض المبالغ والتواريخ بكل شاشات التطبيق
class AppFormatters {
  const AppFormatters._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'ar',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final _dateFormat = DateFormat('d MMM yyyy', 'ar');

  static String currency(double value) => _currencyFormat.format(value);

  static String date(DateTime value) => _dateFormat.format(value);
}
