import 'package:intl/intl.dart';

class Format {
  static final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _date = DateFormat('dd/MM/yyyy');

  static String moneyFromCents(int cents) => _currency.format(cents / 100);
  static String date(DateTime d) => _date.format(d);
}
