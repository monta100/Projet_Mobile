import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Future<void> main() async {
  print('Loading .env...');
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('Warning: .env not found or failed to load: $e');
  }

  final host = dotenv.env['SMTP_HOST'];
  final portStr = dotenv.env['SMTP_PORT'];
  final user = dotenv.env['SMTP_USER'];
  final pass = dotenv.env['SMTP_PASS'];
  final ssl = (dotenv.env['SMTP_SSL'] ?? 'false').toLowerCase() == 'true';
  final to = dotenv.env['SMTP_TEST_TO'] ?? dotenv.env['SMTP_USER'];

  if (host == null || portStr == null || user == null || pass == null) {
    print(
      'Missing SMTP configuration in .env. Please copy .env.example to .env and fill values.',
    );
    return;
  }

  final port = int.tryParse(portStr) ?? 587;
  final smtp = SmtpServer(
    host,
    port: port,
    username: user,
    password: pass,
    ssl: ssl,
    ignoreBadCertificate: true,
  );

  final message = Message()
    ..from = Address(user)
    ..recipients.add(to!)
    ..subject = 'Test d\'envoi SMTP - app_nutrition'
    ..text =
        'Ceci est un message de test envoyé depuis tools/smtp_test.dart le ${DateTime.now()}.';

  print('Attempting to send test email to $to via $host:$port (ssl=$ssl)...');
  try {
    final sendReport = await send(message, smtp);
    print('Email envoyé avec succès: $sendReport');
  } catch (e) {
    print('Erreur lors de l\'envoi de l\'email: $e');
  }
}
