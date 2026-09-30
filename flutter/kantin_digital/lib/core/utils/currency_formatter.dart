import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String rupiah(num value) => _rupiah.format(value);
}

