import 'package:intl/intl.dart';

class Format {
  static String moneyFromCents(int cents) {
    final value = cents / 100.0;
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  static String date(DateTime dt) {
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(dt);
  }

  /// usado nos filtros (ex.: 28/08)
  static String compactDate(DateTime dt) {
    return DateFormat('dd/MM', 'pt_BR').format(dt);
  }
}
