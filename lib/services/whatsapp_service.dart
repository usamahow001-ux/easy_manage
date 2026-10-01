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

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static Future<bool> makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  static Future<bool> sendSms({
    required String phone,
    required String message,
  }) async {
    final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }
}
