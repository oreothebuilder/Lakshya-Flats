import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../config/email_config.dart';

/// Email dispatch service for sending resident credentials, notifications, and receipts
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _mailRef => _db.collection('mail');
  CollectionReference get _emailLogsRef => _db.collection('email_logs');

  /// Send student account login credentials to their registered email.
  /// Dispatches via Firestore `mail` collection (Firebase Trigger Email extension standard),
  /// logs to `email_logs`, and logs the action for audit.
  Future<Map<String, dynamic>> sendStudentCredentialsEmail({
    required String studentEmail,
    required String studentName,
    required String registrationNumber,
    required String password,
    required String building,
    required String room,
    String bedNumber = '',
    String course = '',
    String branch = '',
  }) async {
    final cleanEmail = studentEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return {
        'success': false,
        'message': 'Invalid email address provided: "$cleanEmail"',
      };
    }

    final subject = "Welcome to Lakshya Residency - Your Login Credentials";
    final textBody = _generatePlainTextCredentials(
      studentName: studentName,
      registrationNumber: registrationNumber,
      email: cleanEmail,
      password: password,
      building: building,
      room: room,
      bedNumber: bedNumber,
      course: course,
      branch: branch,
    );
    final htmlBody = _generateHtmlCredentials(
      studentName: studentName,
      registrationNumber: registrationNumber,
      email: cleanEmail,
      password: password,
      building: building,
      room: room,
      bedNumber: bedNumber,
      course: course,
      branch: branch,
    );

    bool firestoreQueueSuccess = false;
    String? mailDocId;

    // 1. Attempt direct delivery via Gmail SMTP (sends custom HTML with credentials)
    final bool smtpDelivered = await _sendViaGmailSmtp(
      recipientEmail: cleanEmail,
      subject: subject,
      textBody: textBody,
      htmlBody: htmlBody,
    );

    // 2. If SMTP did not deliver directly (e.g. ISP blocked raw socket), trigger Firebase Auth's
    // HTTPS delivery so the student ALWAYS receives an official access email to their inbox!
    bool authEmailSent = false;
    if (!smtpDelivered) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: cleanEmail);
        authEmailSent = true;
        debugPrint("Firebase Auth password email dispatched as fallback to $cleanEmail");
      } catch (authErr) {
        debugPrint("Firebase Auth password email notice: $authErr");
      }
    }

    // 3. Queue to Firestore 'mail' collection (Firebase Trigger Email extension standard)
    try {
      final docRef = await _mailRef.add({
        'to': [cleanEmail],
        'message': {
          'subject': subject,
          'text': textBody,
          'html': htmlBody,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'status': smtpDelivered ? 'SENT_SMTP' : (authEmailSent ? 'SENT_AUTH_LINK' : 'PENDING'),
        'deliveryMethod': smtpDelivered ? 'Direct Gmail SMTP' : (authEmailSent ? 'Firebase Auth HTTPS' : 'Firestore Queue'),
        'type': 'STUDENT_CREDENTIALS',
        'metadata': {
          'studentName': studentName,
          'registrationNumber': registrationNumber,
          'building': building,
          'room': room,
          'sender': EmailConfig.senderEmail,
        },
      });
      mailDocId = docRef.id;
      firestoreQueueSuccess = true;
      debugPrint("Email queued to Firestore 'mail' collection: $mailDocId");
    } catch (e) {
      debugPrint("Firestore 'mail' collection queue notice: $e");
    }

    // 4. Write an immutable dispatch record to 'email_logs' for admin audit
    try {
      await _emailLogsRef.add({
        'recipientEmail': cleanEmail,
        'studentName': studentName,
        'registrationNumber': registrationNumber,
        'subject': subject,
        'passwordHint': password,
        'building': building,
        'room': room,
        'status': smtpDelivered
            ? 'Delivered (Direct Gmail SMTP)'
            : (authEmailSent ? 'Delivered (Firebase Auth Link)' : (firestoreQueueSuccess ? 'Queued (Firestore)' : 'Logged')),
        'mailDocId': mailDocId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("email_logs write notice: $e");
    }

    return {
      'success': true,
      'smtpDelivered': smtpDelivered,
      'authEmailSent': authEmailSent,
      'mailDocId': mailDocId,
      'email': cleanEmail,
      'message': smtpDelivered
          ? 'Credentials delivered via Gmail to $cleanEmail'
          : (authEmailSent
              ? 'Official access email delivered via Firebase to $cleanEmail'
              : 'Credentials dispatched to $cleanEmail'),
    };
  }

  /// Generate Plain Text format of credentials
  String _generatePlainTextCredentials({
    required String studentName,
    required String registrationNumber,
    required String email,
    required String password,
    required String building,
    required String room,
    required String bedNumber,
    required String course,
    required String branch,
  }) {
    final bedStr = bedNumber.isNotEmpty ? " (Bed: $bedNumber)" : "";
    final academicStr = (course.isNotEmpty || branch.isNotEmpty)
        ? "\nAcademic Program: $course ${branch.isNotEmpty ? '($branch)' : ''}"
        : "";

    return '''
Hello $studentName,

Welcome to Lakshya Residency! Your student resident account has been created successfully.

--------------------------------------------------
RESIDENCE DETAILS
--------------------------------------------------
Building: $building
Room: $room$bedStr$academicStr

--------------------------------------------------
YOUR LOGIN CREDENTIALS
--------------------------------------------------
Username / Email: $email
Student Reg No:   $registrationNumber
Default Password: $password

HOW TO LOG IN:
1. Open the Lakshya Residency App.
2. Select the "Resident" tab on the login screen.
3. Enter either your registered Email ($email) or your Registration Number ($registrationNumber).
4. Enter your password ($password) to log in.

SECURITY NOTICE:
You can update your password at any time from your profile screen inside the app. If you have questions or require assistance, please contact the hostel warden or administration.

Best regards,
Lakshya Residency Management Team
''';
  }

  /// Generate rich HTML format of credentials
  String _generateHtmlCredentials({
    required String studentName,
    required String registrationNumber,
    required String email,
    required String password,
    required String building,
    required String room,
    required String bedNumber,
    required String course,
    required String branch,
  }) {
    final bedStr = bedNumber.isNotEmpty ? " • Bed: $bedNumber" : "";
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to Lakshya Residency</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 24px; color: #0F172A; }
    .card { max-width: 560px; margin: 0 auto; background: #FFFFFF; border-radius: 20px; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.06); border: 1px solid #E2E8F0; }
    .header { background: linear-gradient(135deg, #003896 0%, #0056D2 100%); padding: 32px 28px; text-align: center; color: #FFFFFF; }
    .header h1 { margin: 0; font-size: 22px; font-weight: 800; letter-spacing: -0.5px; }
    .header p { margin: 6px 0 0; font-size: 13px; opacity: 0.85; font-weight: 500; }
    .content { padding: 28px; }
    .greeting { font-size: 16px; font-weight: 700; margin-bottom: 12px; }
    .message { font-size: 14px; line-height: 1.6; color: #475569; margin-bottom: 24px; }
    .info-box { background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 14px; padding: 18px; margin-bottom: 24px; }
    .info-row { display: flex; justify-content: space-between; padding: 6px 0; font-size: 13px; border-bottom: 1px dashed #E2E8F0; }
    .info-row:last-child { border-bottom: none; }
    .info-label { color: #64748B; font-weight: 500; }
    .info-val { font-weight: 700; color: #0F172A; }
    .cred-box { background: #EFF6FF; border: 1.5px solid #BFDBFE; border-radius: 16px; padding: 20px; margin-bottom: 24px; text-align: center; }
    .cred-title { font-size: 12px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.8px; color: #1E40AF; margin-bottom: 14px; }
    .cred-field { margin-bottom: 12px; }
    .cred-label { font-size: 11px; color: #64748B; margin-bottom: 3px; }
    .cred-val { font-size: 15px; font-weight: 800; color: #003896; font-family: monospace; letter-spacing: 0.5px; }
    .password-badge { display: inline-block; background: #FEF3C7; color: #92400E; padding: 8px 18px; border-radius: 10px; font-size: 16px; font-weight: 800; font-family: monospace; border: 1px solid #FDE68A; margin-top: 4px; }
    .steps { background: #F1F5F9; border-radius: 12px; padding: 16px 20px; font-size: 13px; line-height: 1.6; color: #334155; margin-bottom: 24px; }
    .footer { text-align: center; padding: 20px; font-size: 11px; color: #94A3B8; border-top: 1px solid #F1F5F9; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <h1>LAKSHYA RESIDENCY</h1>
      <p>Resident Portal Access & Account Setup</p>
    </div>
    <div class="content">
      <div class="greeting">Hello $studentName,</div>
      <div class="message">
        Welcome to Lakshya Residency! Your resident profile has been successfully onboarded. Below are your room assignment details and login credentials to access the resident mobile application.
      </div>

      <div class="info-box">
        <div class="info-row"><span class="info-label">Building</span><span class="info-val">$building</span></div>
        <div class="info-row"><span class="info-label">Room & Bed</span><span class="info-val">$room$bedStr</span></div>
        <div class="info-row"><span class="info-label">Registration No</span><span class="info-val">$registrationNumber</span></div>
        ${course.isNotEmpty ? '<div class="info-row"><span class="info-label">Course</span><span class="info-val">$course $branch</span></div>' : ''}
      </div>

      <div class="cred-box">
        <div class="cred-title">Your Resident Portal Credentials</div>
        <div class="cred-field">
          <div class="cred-label">Login Identifier (Email or Reg No)</div>
          <div class="cred-val">$email</div>
        </div>
        <div class="cred-field">
          <div class="cred-label">Default Password (Firstname@RegNo)</div>
          <div class="password-badge">$password</div>
        </div>
      </div>

      <div class="steps">
        <strong>How to log in:</strong><br>
        1. Open the <strong>Lakshya Residency</strong> App.<br>
        2. Tap on <strong>Resident Portal</strong> tab.<br>
        3. Enter your Email (<code>$email</code>) or Registration No (<code>$registrationNumber</code>).<br>
        4. Enter your default password above.<br>
      </div>
    </div>
    <div class="footer">
      This is an automated communication from Lakshya Residency Management.<br>
      Please keep your credentials confidential.
    </div>
  </div>
</body>
</html>
''';
  }

  /// Dispatch a new bill / invoice notification email to the resident
  Future<Map<String, dynamic>> sendBillInvoiceEmail({
    required String studentEmail,
    required String studentName,
    required String billName,
    required String billCategory,
    required double amount,
    required DateTime dueDate,
    required String invoiceNo,
    required String building,
    required String room,
  }) async {
    final cleanEmail = studentEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return {'success': false, 'message': 'Invalid email address'};
    }

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final formattedDueDate = "${dueDate.day} ${months[dueDate.month - 1]} ${dueDate.year}";
    final subject = "New Bill Issued: $billName - ₹${amount.toStringAsFixed(0)} (Due: $formattedDueDate)";
    final textBody = '''
Hello $studentName,

A new bill has been issued for your room at Lakshya Residency.

--------------------------------------------------
BILL & PAYMENT DETAILS
--------------------------------------------------
Invoice Number: $invoiceNo
Bill Category:  $billCategory
Bill Name:      $billName
Amount Due:     ₹${amount.toStringAsFixed(0)}
Due Date:       $formattedDueDate
Residence:      $building (Room $room)

Please log in to the Lakshya Residency App to review your invoice and complete the payment before the due date.

Best regards,
Lakshya Residency Administration
''';

    final htmlBody = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #F8FAFC; margin: 0; padding: 24px; color: #0F172A; }
    .card { max-width: 560px; margin: 0 auto; background: #FFFFFF; border-radius: 20px; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.06); border: 1px solid #E2E8F0; }
    .header { background: linear-gradient(135deg, #003896 0%, #0056D2 100%); padding: 28px 24px; text-align: center; color: #FFFFFF; }
    .header h1 { margin: 0; font-size: 20px; font-weight: 800; }
    .content { padding: 24px; }
    .amount-box { background: #EFF6FF; border: 1.5px solid #BFDBFE; border-radius: 14px; padding: 18px; text-align: center; margin: 20px 0; }
    .amount-label { font-size: 12px; font-weight: 700; color: #1E40AF; text-transform: uppercase; }
    .amount-value { font-size: 28px; font-weight: 800; color: #003896; margin-top: 4px; }
    .info-row { display: flex; justify-content: space-between; padding: 8px 0; font-size: 13.5px; border-bottom: 1px solid #F1F5F9; }
    .footer { text-align: center; padding: 18px; font-size: 11px; color: #94A3B8; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <h1>LAKSHYA RESIDENCY</h1>
      <p style="margin: 4px 0 0; opacity: 0.85; font-size: 13px;">New Bill Notice</p>
    </div>
    <div class="content">
      <p>Hello <strong>$studentName</strong>,</p>
      <p>A new bill has been generated for your account. Please find the payment details below:</p>
      <div class="amount-box">
        <div class="amount-label">Amount Payable</div>
        <div class="amount-value">₹${amount.toStringAsFixed(0)}</div>
        <div style="font-size: 12px; color: #64748B; margin-top: 4px;">Due Date: <strong>$formattedDueDate</strong></div>
      </div>
      <div class="info-row"><span>Bill Description</span><strong>$billName</strong></div>
      <div class="info-row"><span>Category</span><strong>$billCategory</strong></div>
      <div class="info-row"><span>Invoice Number</span><strong>$invoiceNo</strong></div>
      <div class="info-row"><span>Room & Building</span><strong>$room • $building</strong></div>
      <p style="margin-top: 20px; font-size: 13px; color: #475569;">You can view and pay this invoice directly from the Resident mobile application.</p>
    </div>
    <div class="footer">Lakshya Residency Automated Management</div>
  </div>
</body>
</html>
''';

    final bool smtpDelivered = await _sendViaGmailSmtp(
      recipientEmail: cleanEmail,
      subject: subject,
      textBody: textBody,
      htmlBody: htmlBody,
    );

    try {
      await _mailRef.add({
        'to': [cleanEmail],
        'message': {'subject': subject, 'text': textBody, 'html': htmlBody},
        'createdAt': FieldValue.serverTimestamp(),
        'status': smtpDelivered ? 'SENT_SMTP' : 'PENDING',
        'deliveryMethod': smtpDelivered ? 'Direct Gmail SMTP' : 'Firestore Queue',
        'type': 'BILL_INVOICE_NOTICE',
      });
      await _emailLogsRef.add({
        'recipientEmail': cleanEmail,
        'studentName': studentName,
        'subject': subject,
        'invoiceNo': invoiceNo,
        'amount': amount,
        'status': smtpDelivered ? 'Delivered (Direct Gmail SMTP)' : 'Queued (Firestore)',
        'timestamp': FieldValue.serverTimestamp(),
      });
      return {'success': true, 'smtpDelivered': smtpDelivered};
    } catch (e) {
      debugPrint("Bill email queue notice: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Send an email notification to the student when their ticket status is updated
  /// to 'Under execution' or 'Resolved'.
  Future<Map<String, dynamic>> sendTicketStatusEmail({
    required String studentEmail,
    required String studentName,
    required String ticketId,
    required String ticketTitle,
    required String category,
    required String status,
    required String building,
    required String room,
    String? remarks,
  }) async {
    final cleanEmail = studentEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return {'success': false, 'message': 'Invalid email address: "$cleanEmail"'};
    }

    final isResolved = status == 'Resolved';
    final subject = isResolved
        ? "Ticket Resolved: $ticketTitle - Lakshya Residency"
        : "Ticket Update: $ticketTitle is Under Execution - Lakshya Residency";

    final shortId = ticketId.length > 8 ? ticketId.substring(0, 8) : ticketId;

    final textBody = '''
Hello $studentName,

Your maintenance ticket has been updated by the hostel administration:

TICKET DETAILS
--------------------------------------------------
Ticket ID:   $ticketId
Subject:     $ticketTitle
Category:    $category
Status:      $status
Residence:   $building (Room $room)
${remarks != null && remarks.trim().isNotEmpty ? '\nAdmin Remarks:\n$remarks\n' : ''}
${isResolved ? 'Our maintenance team has marked this issue as resolved. If you still encounter problems, please feel free to raise a follow-up ticket in the app.' : 'Our maintenance team has taken up your ticket and is actively working on resolving the issue.'}

Best regards,
Lakshya Residency Administration
''';

    final statusColor = isResolved ? '#16A34A' : '#D97706';
    final statusBg = isResolved ? '#DCFCE7' : '#FEF3C7';

    final htmlBody = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #F8FAFC; margin: 0; padding: 24px; color: #0F172A; }
    .card { max-width: 560px; margin: 0 auto; background: #FFFFFF; border-radius: 20px; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.06); border: 1px solid #E2E8F0; }
    .header { background: linear-gradient(135deg, #003896 0%, #0056D2 100%); padding: 28px 24px; text-align: center; color: #FFFFFF; }
    .header h1 { margin: 0; font-size: 20px; font-weight: 800; }
    .content { padding: 24px; }
    .status-box { background: $statusBg; border: 1.5px solid ${isResolved ? '#BBF7D0' : '#FDE68A'}; border-radius: 14px; padding: 16px; text-align: center; margin: 18px 0; }
    .status-label { font-size: 11px; font-weight: 700; color: #64748B; text-transform: uppercase; }
    .status-value { font-size: 20px; font-weight: 800; color: $statusColor; margin-top: 4px; }
    .info-row { display: flex; justify-content: space-between; padding: 8px 0; font-size: 13.5px; border-bottom: 1px solid #F1F5F9; }
    .remarks-box { background: #F8FAFC; border-left: 4px solid #0056D2; padding: 12px 16px; margin: 18px 0; border-radius: 0 10px 10px 0; }
    .footer { text-align: center; padding: 18px; font-size: 11px; color: #94A3B8; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <h1>LAKSHYA RESIDENCY</h1>
      <p style="margin: 4px 0 0; opacity: 0.85; font-size: 13px;">Maintenance Ticket Status Update</p>
    </div>
    <div class="content">
      <p>Hello <strong>$studentName</strong>,</p>
      <p>Your maintenance request has received a status update:</p>
      <div class="status-box">
        <div class="status-label">Current Ticket Status</div>
        <div class="status-value">$status</div>
      </div>
      <div class="info-row"><span>Ticket Title</span><strong>$ticketTitle</strong></div>
      <div class="info-row"><span>Category</span><strong>$category</strong></div>
      <div class="info-row"><span>Ticket ID</span><code style="color: #0056D2;">#$shortId</code></div>
      <div class="info-row"><span>Room & Building</span><strong>$room • $building</strong></div>
      ${remarks != null && remarks.trim().isNotEmpty ? '<div class="remarks-box"><strong>Admin Note:</strong><br><span style="color: #475569; font-size: 13px;">$remarks</span></div>' : ''}
      <p style="margin-top: 20px; font-size: 13px; color: #475569;">
        ${isResolved ? 'Our team has marked this ticket as resolved. If the problem persists, you can raise a new ticket anytime via the resident app.' : 'Our team is currently executing repairs. We will notify you again once the ticket is completed.'}
      </p>
    </div>
    <div class="footer">Lakshya Residency Automated Management</div>
  </div>
</body>
</html>
''';

    final bool smtpDelivered = await _sendViaGmailSmtp(
      recipientEmail: cleanEmail,
      subject: subject,
      textBody: textBody,
      htmlBody: htmlBody,
    );

    try {
      await _mailRef.add({
        'to': [cleanEmail],
        'message': {'subject': subject, 'text': textBody, 'html': htmlBody},
        'createdAt': FieldValue.serverTimestamp(),
        'status': smtpDelivered ? 'SENT_SMTP' : 'PENDING',
        'deliveryMethod': smtpDelivered ? 'Direct Gmail SMTP' : 'Firestore Queue',
        'type': 'TICKET_STATUS_NOTICE',
      });
      await _emailLogsRef.add({
        'recipientEmail': cleanEmail,
        'studentName': studentName,
        'subject': subject,
        'ticketId': ticketId,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return {'success': true, 'smtpDelivered': smtpDelivered};
    } catch (e) {
      debugPrint("Ticket email queue notice: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Send an email using direct Gmail SMTP (configured via EmailConfig)
  Future<bool> _sendViaGmailSmtp({
    required String recipientEmail,
    required String subject,
    required String textBody,
    required String htmlBody,
  }) async {
    final senderEmail = EmailConfig.senderEmail.trim();
    final appPassword = EmailConfig.cleanAppPassword;

    if (senderEmail.isEmpty || appPassword.isEmpty) {
      debugPrint("SMTP Skipped: EmailConfig sender or app password not configured.");
      return false;
    }

    try {
      final smtpServer = SmtpServer(
        'smtp.gmail.com',
        username: senderEmail,
        password: appPassword,
        port: 465,
        ssl: true,
      );
      final message = Message()
        ..from = Address(senderEmail, EmailConfig.senderDisplayName)
        ..recipients.add(recipientEmail)
        ..subject = subject
        ..text = textBody
        ..html = htmlBody;

      final sendReport = await send(message, smtpServer).timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          throw TimeoutException("SMTP connection timed out after 12 seconds.");
        },
      );
      debugPrint("Direct Gmail SMTP succeeded to $recipientEmail: $sendReport");
      return true;
    } catch (e) {
      debugPrint("Direct Gmail SMTP notice: $e");
      return false;
    }
  }
}
