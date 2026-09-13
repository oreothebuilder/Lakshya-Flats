/// Central Email and SMTP configuration for Lakshya Residency
class EmailConfig {
  /// Sender Gmail address used for sending official credentials and notifications.
  /// Can be injected at build time via --dart-define=SMTP_SENDER_EMAIL=...
  static const String senderEmail = String.fromEnvironment(
    'SMTP_SENDER_EMAIL',
    defaultValue: "sudhansu1906@gmail.com",
  );

  /// Google App Password (16 characters generated from Google Account Security).
  /// Can be securely injected at build time via --dart-define=SMTP_APP_PASSWORD=...
  static const String appPassword = String.fromEnvironment(
    'SMTP_APP_PASSWORD',
    defaultValue: "iixp hrqc ziss eadm",
  );

  /// Friendly display name in the student's email inbox
  static const String senderDisplayName = "Lakshya Residency Management";

  /// Clean password without spaces for SMTP authentication
  static String get cleanAppPassword => appPassword.replaceAll(' ', '').trim();
}
