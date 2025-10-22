import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Map<String, String> _loadDotEnv(File file) {
  final map = <String, String>{};
  if (!file.existsSync()) return map;
  final lines = file.readAsLinesSync();
  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('#')) continue;
    final idx = line.indexOf('=');
    if (idx <= 0) continue;
    final key = line.substring(0, idx).trim();
    var value = line.substring(idx + 1).trim();
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
    } else if (value.startsWith("'") && value.endsWith("'")) {
      value = value.substring(1, value.length - 1);
    }
    map[key] = value;
  }
  return map;
}

Future<void> main() async {
  print('Loading .env from project root...');
  final envFile = File('.env');
  final env = _loadDotEnv(envFile);

  final host = env['SMTP_HOST'];
  final portStr = env['SMTP_PORT'];
  final user = env['SMTP_USER'];
  final pass = env['SMTP_PASS'];
  final ssl = (env['SMTP_SSL'] ?? 'false').toLowerCase() == 'true';
  final to = env['SMTP_TEST_TO'] ?? env['SMTP_USER'];

  final missing = <String>[];
  if (host == null) missing.add('SMTP_HOST');
  if (portStr == null) missing.add('SMTP_PORT');
  if (user == null) missing.add('SMTP_USER');
  if (pass == null) missing.add('SMTP_PASS');

  if (missing.isNotEmpty) {
    print(
      'Missing SMTP configuration in .env. The following keys are missing: ${missing.join(', ')}.',
    );
    print(
      'Please copy .env.example to .env and fill values (do NOT commit .env).',
    );
    return;
  }

  final port = int.tryParse(portStr!) ?? 587;
  final smtp = SmtpServer(
    host!,
    port: port,
    username: user!,
    password: pass!,
    ssl: ssl,
    ignoreBadCertificate: true,
  );

  final message = Message()
    ..from = Address(user)
    ..recipients.add(to!)
    ..subject = 'Test d\'envoi SMTP - app_nutrition'
    ..text =
        'Ceci est un message de test envoyé depuis tools/smtp_test_cli.dart le ${DateTime.now()}.';

  print('Attempting to send test email to $to via $host:$port (ssl=$ssl)...');
  try {
    final sendReport = await send(message, smtp);
    print('Email envoyé avec succès: $sendReport');
  } catch (e) {
    print('Erreur lors de l\'envoi de l\'email: $e');
    // Provide extra guidance for common Gmail authentication failures
    final errStr = e.toString();
    if (errStr.contains('Authentication') ||
        errStr.contains('BadCredentials') ||
        errStr.contains('535')) {
      print('\nDiagnostic rapide pour l\'erreur 535 (BadCredentials):');
      print(
        '- Vérifiez que le champ SMTP_USER contient l\'adresse complète (e.g. user@gmail.com).',
      );
      print(
        '- Assurez-vous d\'avoir activé l\'authentification à 2 facteurs (2FA) pour ce compte Google.',
      );
      print(
        '- Créez un App Password dans votre compte Google (Security → App passwords) et utilisez-le dans SMTP_PASS.',
      );
      print(
        '- N\'ajoutez pas l\'App Password dans les fichiers suivis par git. Mettez-le uniquement dans `.env` local.',
      );
      print(
        '- Si le mot de passe a été exposé, révoquez-le immédiatement et générez-en un nouveau.',
      );
      print(
        '- Pour plus d\'infos: https://support.google.com/mail/?p=BadCredentials',
      );
    }
    // If the exception is a MailerException we can print server response details
    if (e is MailerException) {
      for (var p in e.problems) {
        print('\nServer response: ${p.code} - ${p.msg}');
      }
    }
  }
}
