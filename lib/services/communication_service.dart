import 'package:url_launcher/url_launcher.dart';

/// פעולות תקשורת עם איש קשר — שיחה, וואטסאפ, מייל.
class CommunicationService {
  static String _cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-()]'), '');
  }

  static Future<bool> call(String phone) async {
    final uri = Uri(scheme: 'tel', path: _cleanPhone(phone));
    return _launch(uri);
  }

  static Future<bool> whatsapp(String phone, {String? message}) async {
    var p = _cleanPhone(phone);
    // המרת מספר ישראלי מקומי לפורמט בינלאומי בסיסי.
    if (p.startsWith('0')) {
      p = '972${p.substring(1)}';
    }
    final text = message != null ? '?text=${Uri.encodeComponent(message)}' : '';
    final uri = Uri.parse('https://wa.me/$p$text');
    return _launch(uri);
  }

  static Future<bool> email(String address, {String? subject, String? body}) async {
    final params = <String, String>{};
    if (subject != null) params['subject'] = subject;
    if (body != null) params['body'] = body;
    final uri = Uri(
      scheme: 'mailto',
      path: address,
      query: params.entries
          .map((e) =>
              '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&'),
    );
    return _launch(uri);
  }

  static Future<bool> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
