import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/services.dart' show rootBundle;

class EmailService {
  final String smtpHost;
  final int smtpPort;
  final String username;
  final String password;
  final bool useSsl;
  // Optional: public URL to a logo image to display in emails
  final String? logoUrl;

  EmailService({
    required this.smtpHost,
    required this.smtpPort,
    required this.username,
    required this.password,
    this.useSsl = true,
    this.logoUrl,
  });

  Future<bool> _trySend(
    Message message,
    SmtpServer server, {
    String label = 'primary',
  }) async {
    try {
      final sendReport = await send(message, server);
      // ignore: avoid_print
      print('Email envoyé via $label: $sendReport');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Erreur envoi email ($label): $e');
      if (e is MailerException) {
        for (var p in e.problems) {
          // ignore: avoid_print
          print(' - SMTP response: ${p.code} ${p.msg}');
        }
      }
      return false;
    }
  }

  Future<bool> _sendMessage(Message message) async {
    final primaryServer = SmtpServer(
      smtpHost,
      port: smtpPort,
      username: username,
      password: password,
      ignoreBadCertificate: true,
      ssl: useSsl,
    );

    // 1) Try primary settings
    final okPrimary = await _trySend(
      message,
      primaryServer,
      label: 'primary ${smtpHost}:${smtpPort} ssl=${useSsl}',
    );
    if (okPrimary) return true;

    // 2) Fallback: toggle SSL/port between 587 (STARTTLS) and 465 (SSL)
    int altPort;
    bool altSsl;
    if (smtpPort == 587 && !useSsl) {
      altPort = 465;
      altSsl = true;
    } else if (smtpPort == 465 && useSsl) {
      altPort = 587;
      altSsl = false;
    } else {
      altPort = 465;
      altSsl = true;
    }

    final altServer = SmtpServer(
      smtpHost,
      port: altPort,
      username: username,
      password: password,
      ignoreBadCertificate: true,
      ssl: altSsl,
    );
    final okAlt = await _trySend(
      message,
      altServer,
      label: 'fallback ${smtpHost}:$altPort ssl=$altSsl',
    );
    if (okAlt) return true;

    // 3) Gmail explicit fallbacks
    if (smtpHost.contains('gmail.com')) {
      final gmail465 = SmtpServer(
        'smtp.gmail.com',
        port: 465,
        username: username,
        password: password,
        ssl: true,
        ignoreBadCertificate: true,
      );
      if (await _trySend(message, gmail465, label: 'gmail:465 ssl=true')) {
        return true;
      }

      final gmail587 = SmtpServer(
        'smtp.gmail.com',
        port: 587,
        username: username,
        password: password,
        ssl: false,
        ignoreBadCertificate: true,
      );
      if (await _trySend(message, gmail587, label: 'gmail:587 STARTTLS')) {
        return true;
      }
    }

    return false;
  }

  Future<bool> sendVerificationEmail(String toEmail, String code) async {
    final message = Message()
      ..from = Address(username)
      ..recipients.add(toEmail)
      ..subject = 'Votre code de vérification'
      ..text =
          'Votre code de vérification est: $code\n\nSaisissez ce code dans l\'application pour activer ou réinitialiser votre compte.';

    return _sendMessage(message);
  }

  Future<bool> sendVerificationEmailRich({
    required String toEmail,
    required String code,
    required String userName,
    required String action,
    String appName = 'App Nutrition',
    int validityMinutes = 10,
  }) async {
    final subject = '🔐 Code de vérification pour votre compte';

    // Plain-text fallback
    final bodyText = [
      'Bonjour $userName,',
      '',
      'Vous avez demandé à $action votre compte sur $appName.',
      'Pour confirmer cette opération, veuillez utiliser le code ci-dessous :',
      '',
      'Code de vérification : $code',
      '',
      'Ce code est valable pendant $validityMinutes minutes.',
      'Si vous n’êtes pas à l’origine de cette demande, ignorez cet e-mail.',
      '',
      'L’équipe $appName vous remercie',
    ].join('\n');

    // HTML version (inline styles for email clients)
    final primary = '#4CAF50';
    final attachments = <Attachment>[];
    String logoBlock;
    bool hasLogoImage = false;
    String? logoImgHtml;
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      // Prefer external URL if provided
      hasLogoImage = true;
      logoImgHtml =
          '<img src="${logoUrl!}" alt="${appName}" style="height:56px;width:auto;display:inline-block;" />';
    } else {
      // Fallback: try to load inline asset from assets/email/logo.png and attach as CID
      try {
        final data = (await rootBundle.load(
          'assets/email/logo.png',
        )).buffer.asUint8List();
        final cid = 'app_logo';
        final att = StreamAttachment(Stream.value(data), 'logo.png')
          ..contentType = 'image/png'
          ..cid = cid;
        attachments.add(att);
        hasLogoImage = true;
        logoImgHtml =
            '<img src="cid:$cid" alt="$appName" style="height:56px;width:auto;display:inline-block;" />';
      } catch (e) {
        // ignore: avoid_print
        print(
          'EmailService: inline logo asset not found (assets/email/logo.png): $e',
        );
      }
    }
    // Build header: show both logo and app name when logo is available; otherwise show name only
    if (hasLogoImage && logoImgHtml != null) {
      logoBlock =
          '<div style="display:inline-flex;flex-direction:column;align-items:center;gap:8px;justify-content:center;">$logoImgHtml<span style="font-size:22px;font-weight:700;color:$primary;display:inline-block;">$appName</span></div>';
    } else {
      logoBlock =
          '<div style="font-size:22px;font-weight:700;color:$primary;">$appName</div>';
    }
    final bodyHtml =
        '''
<!DOCTYPE html>
<html lang="fr">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>$subject</title>
  </head>
  <body style="margin:0;padding:0;background-color:#f4f6f8;font-family:Arial,Helvetica,sans-serif;color:#222;">
    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background-color:#f4f6f8;padding:24px 12px;">
      <tr>
        <td align="center">
          <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="max-width:600px;">
            <tr>
              <td style="padding:16px 12px;text-align:center;">
                $logoBlock
              </td>
            </tr>
            <tr>
              <td style="background:#ffffff;border-radius:12px;padding:28px 24px;box-shadow:0 6px 24px rgba(0,0,0,0.06);">
                <h1 style="margin:0 0 12px 0;font-size:22px;color:#111;">🔐 Code de vérification</h1>
                <p style="margin:0 0 16px 0;line-height:1.6;font-size:14px;color:#333;">
                  Bonjour <strong>$userName</strong>,<br/>
                  Vous avez demandé à <strong>$action</strong> votre compte sur <strong>$appName</strong>.<br/>
                  Pour confirmer cette opération, utilisez le code ci-dessous :
                </p>
                <div style="text-align:center;margin:22px 0;">
                  <div style="display:inline-block;background:#fff;border:2px solid $primary;border-radius:10px;padding:18px 28px;">
                    <span style="font-size:28px;letter-spacing:2px;font-weight:800;color:#111;">$code</span>
                  </div>
                </div>
                <p style="margin:0 0 16px 0;line-height:1.6;font-size:13px;color:#555;">
                  Ce code est valable pendant <strong>$validityMinutes minutes</strong>.<br/>
                  Si vous n’êtes pas à l’origine de cette demande, ignorez simplement cet e-mail — votre compte restera sécurisé.
                </p>
                <p style="margin:20px 0 0 0;font-size:13px;color:#333;">L’équipe <strong>$appName</strong> vous remercie</p>
              </td>
            </tr>
            <tr>
              <td style="padding:16px 8px;text-align:center;color:#999;font-size:11px;">
                Cet e-mail a été envoyé automatiquement. Merci de ne pas y répondre.
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
  </html>
''';

    final message = Message()
      ..from = Address(username)
      ..recipients.add(toEmail)
      ..subject = subject
      ..text = bodyText
      ..html = bodyHtml;
    if (attachments.isNotEmpty) {
      message.attachments.addAll(attachments);
    }

    return _sendMessage(message);
  }
}
