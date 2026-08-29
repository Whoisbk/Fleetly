import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

abstract final class CurrencyFormatter {
  static final _format = NumberFormat.currency(
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 0,
  );

  static String format(num amount) => _format.format(amount);
}
