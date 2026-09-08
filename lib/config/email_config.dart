/// Central Email and SMTP configuration for Lakshya Residency
class EmailConfig {
  /// Sender Gmail address used for sending official credentials and notifications
  static const String senderEmail = "sudhansu1906@gmail.com";

  /// Google App Password (16 characters generated from Google Account Security)
  static const String appPassword = "iixp hrqc ziss eadm";

  /// Friendly display name in the student's email inbox
  static const String senderDisplayName = "Lakshya Residency Management";

  /// Clean password without spaces for SMTP authentication
  static String get cleanAppPassword => appPassword.replaceAll(' ', '').trim();
}
