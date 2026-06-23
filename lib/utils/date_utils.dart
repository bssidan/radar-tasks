import 'package:intl/intl.dart';

class DateUtils {
  static final _dateFmt = DateFormat('dd/MM/yyyy', 'he');
  static final _dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm', 'he');

  static String formatDate(DateTime? d) {
    if (d == null) return '—';
    return _dateFmt.format(d);
  }

  static String formatTime(int? minutesFromMidnight) {
    if (minutesFromMidnight == null) return '';
    final h = (minutesFromMidnight ~/ 60).toString().padLeft(2, '0');
    final m = (minutesFromMidnight % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String formatDateTime(DateTime? d) {
    if (d == null) return '—';
    return _dateTimeFmt.format(d);
  }

  /// תיאור יחסי קצר: היום / מחר / אתמול / תאריך.
  static String relativeLabel(DateTime? d) {
    if (d == null) return 'ללא תאריך';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'היום';
    if (diff == 1) return 'מחר';
    if (diff == -1) return 'אתמול';
    if (diff < 0) return 'באיחור (${formatDate(d)})';
    return formatDate(d);
  }
}
