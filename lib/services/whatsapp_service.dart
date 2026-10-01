import 'package:url_launcher/url_launcher.dart';
import '../models/party.dart';
import '../models/business_profile.dart';

class WhatsAppService {
  static Future<bool> sendPaymentReminder({
    required Party party,
    required double balance,
    required BusinessProfile business,
    required String template,
  }) async {
    final cleanPhone = party.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    var formattedPhone = cleanPhone;
    if (formattedPhone.startsWith('03')) {
      formattedPhone = '92${formattedPhone.substring(1)}'; // Pakistan international code
    } else if (formattedPhone.startsWith('07') && formattedPhone.length == 11) {
      formattedPhone = '44${formattedPhone.substring(1)}'; // UK code
    }

    final message = template
        .replaceAll('{name}', party.name)
        .replaceAll('{business}', business.businessName)
        .replaceAll('{currency}', business.currencySymbol)
        .replaceAll('{balance}', balance.abs().toStringAsFixed(0));

    final uri = Uri.parse(
      'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}',
    );

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      return true;
    } catch (_) {
      try {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        return false;
      }
    }
  }

  static Future<bool> makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendSms({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('sms:$cleanPhone?body=${Uri.encodeComponent(message)}');
    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }
}
