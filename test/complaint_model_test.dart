import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_residency/models/complaint_model.dart';

void main() {
  group('ComplaintModel Tests', () {
    test('Defaults status to Received', () {
      final ticket = ComplaintModel(
        id: 'tkt_1',
        studentId: 'stud_123',
        studentName: 'Aarav Sharma',
        building: 'Lakshya',
        room: 'Room 304',
        title: 'Geyser not heating',
        category: 'Electrical',
        description: 'No hot water in the morning.',
      );

      expect(ticket.status, ComplaintModel.statusReceived);
      expect(ticket.isReceived, isTrue);
      expect(ticket.isUnderExecution, isFalse);
      expect(ticket.isResolved, isFalse);
    });

    test('Status normalization maps legacy statuses correctly', () {
      expect(ComplaintModel.normalizeStatus('Pending'), ComplaintModel.statusReceived);
      expect(ComplaintModel.normalizeStatus('Open'), ComplaintModel.statusReceived);
      expect(ComplaintModel.normalizeStatus('Received'), ComplaintModel.statusReceived);
      expect(ComplaintModel.normalizeStatus('received'), ComplaintModel.statusReceived);

      expect(ComplaintModel.normalizeStatus('In Progress'), ComplaintModel.statusUnderExecution);
      expect(ComplaintModel.normalizeStatus('In-Progress'), ComplaintModel.statusUnderExecution);
      expect(ComplaintModel.normalizeStatus('Under execution'), ComplaintModel.statusUnderExecution);
      expect(ComplaintModel.normalizeStatus('under execution'), ComplaintModel.statusUnderExecution);

      expect(ComplaintModel.normalizeStatus('Resolved'), ComplaintModel.statusResolved);
      expect(ComplaintModel.normalizeStatus('resolved'), ComplaintModel.statusResolved);
      expect(ComplaintModel.normalizeStatus(null), ComplaintModel.statusReceived);
    });

    test('Supports three valid lifecycle statuses', () {
      expect(ComplaintModel.validStatuses, [
        'Received',
        'Under execution',
        'Resolved',
      ]);
    });

    test('toMap and copyWith preserve updated fields and remarks', () {
      final ticket = ComplaintModel(
        id: 'tkt_2',
        studentId: 'stud_456',
        studentName: 'Priya Patel',
        studentPhone: '9876543210',
        building: 'Univ Homes',
        room: 'Room 102',
        title: 'Wi-Fi disconnects frequently',
        category: 'WiFi / Internet',
        description: 'Router loses signal every 10 minutes.',
      );

      final updated = ticket.copyWith(
        status: ComplaintModel.statusUnderExecution,
        adminRemarks: 'Router reboot scheduled with IT admin',
      );

      expect(updated.status, ComplaintModel.statusUnderExecution);
      expect(updated.isUnderExecution, isTrue);
      expect(updated.adminRemarks, 'Router reboot scheduled with IT admin');

      final map = updated.toMap();
      expect(map['status'], 'Under execution');
      expect(map['studentPhone'], '9876543210');
      expect(map['adminRemarks'], 'Router reboot scheduled with IT admin');
    });
  });
}
