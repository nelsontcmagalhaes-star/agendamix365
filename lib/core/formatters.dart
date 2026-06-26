import 'package:intl/intl.dart';

class AppFormatters {
  static final _dateFormatter = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _timeFormatter = DateFormat('HH:mm', 'pt_BR');
  static final _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
  static final _dayMonthFormatter = DateFormat('dd/MM', 'pt_BR');
  static final _monthYearFormatter = DateFormat('MMMM yyyy', 'pt_BR');
  static final _weekdayFormatter = DateFormat('EEEE', 'pt_BR');
  static final _shortWeekdayFormatter = DateFormat('EEE', 'pt_BR');
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static String formatDate(DateTime date) => _dateFormatter.format(date);
  static String formatTime(DateTime time) => _timeFormatter.format(time);
  static String formatDateTime(DateTime dt) => _dateTimeFormatter.format(dt);
  static String formatDayMonth(DateTime dt) => _dayMonthFormatter.format(dt);
  static String formatMonthYear(DateTime dt) => _monthYearFormatter.format(dt);
  static String formatWeekday(DateTime dt) => _weekdayFormatter.format(dt);
  static String formatShortWeekday(DateTime dt) => _shortWeekdayFormatter.format(dt);
  static String formatCurrency(double value) => _currencyFormatter.format(value);

  static DateTime? parseDate(String s) {
    try {
      return _dateFormatter.parse(s);
    } catch (_) {
      return null;
    }
  }

  static double? parseCurrency(String s) {
    try {
      final cleaned = s.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
      return double.parse(cleaned);
    } catch (_) {
      return null;
    }
  }

  static String greetingByHour() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  static String daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Amanhã';
    if (diff == -1) return 'Ontem';
    if (diff > 0) return 'Daqui a $diff dias';
    return 'Há ${-diff} dias';
  }

  static String relativeDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Hoje, ${formatTime(date)}';
    if (diff == 1) return 'Amanhã, ${formatTime(date)}';
    if (diff == -1) return 'Ontem, ${formatTime(date)}';
    return '${formatDate(date)}, ${formatTime(date)}';
  }
}
