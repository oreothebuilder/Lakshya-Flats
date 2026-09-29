import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_residency/services/push_notification_service.dart';

void main() {
  group('PushNotificationService Tests', () {
    test('PushNotificationService constants are configured correctly', () {
      expect(PushNotificationService.projectId, 'lakshya-flats');
      expect(PushNotificationService.channelId, 'lakshya_high_importance_channel');
      expect(PushNotificationService.channelName, 'Lakshya High Priority Notifications');
    });

    test('sanitizeTopic produces valid FCM topic strings', () {
      expect(PushNotificationService.sanitizeTopic('All Students'), 'all_students');
      expect(PushNotificationService.sanitizeTopic('Univ Homes Mess #1'), 'univ_homes_mess_1');
      expect(PushNotificationService.sanitizeTopic('  Ishaan-Residency/B-Wing  '), 'ishaan-residency_b-wing');
      expect(PushNotificationService.sanitizeTopic('STU-100025@2026'), 'stu-100025_2026');
      expect(PushNotificationService.sanitizeTopic('Special*&^%Chars'), 'special_%chars');
    });

    test('Singleton instance returns the same instance', () {
      final s1 = PushNotificationService();
      final s2 = PushNotificationService();
      expect(identical(s1, s2), isTrue);
    });
  });
}
