import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  final String smtpHost;
  final int smtpPort;
  final String username;
  final String password;
  final bool useSsl;

  EmailService({
    required this.smtpHost,
    required this.smtpPort,
    required this.username,
    required this.password,
    this.useSsl = true,
  });

  Future<bool> sendVerificationEmail(String toEmail, String code) async {
    final smtpServer = SmtpServer(
      smtpHost,
      port: smtpPort,
      username: username,
      password: password,
      ignoreBadCertificate: true,
      ssl: useSsl,
    );

    final message = Message()
      ..from = Address(username)
      ..recipients.add(toEmail)
      ..subject = 'Votre code de vérification'
      ..text =
          'Votre code de vérification est: $code\n\nSaisissez ce code dans l\'application pour activer votre compte.';

    try {
      final sendReport = await send(message, smtpServer);
      print('Email envoyé: ' + sendReport.toString());
      return true;
    } catch (e) {
      print('Erreur envoi email: $e');
      return false;
    }
  }
}
