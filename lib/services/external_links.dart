import 'package:url_launcher/url_launcher.dart';

class ExternalLinks {
  const ExternalLinks._();

  static final Uri consentForm = Uri.parse(
    'https://www.robertveldmantattoo.nl/toestemmingsformulier-tatoeage/',
  );

  static Future<bool> openConsentForm() => openUri(consentForm);

  static Future<bool> openWebsite(String url) {
    return openUri(Uri.parse(url));
  }

  static Future<bool> openUri(Uri uri) async {
    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
    } catch (_) {
      return false;
    }
  }
}
