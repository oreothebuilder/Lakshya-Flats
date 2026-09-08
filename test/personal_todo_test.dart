import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_residency/models/personal_todo_model.dart';

void main() {
  group('PersonalTodoModel Tests', () {
    test('PersonalTodoModel initializes with defaults', () {
      final todo = PersonalTodoModel(
        id: 'todo_1',
        title: 'Review electricity meter reading',
      );

      expect(todo.id, 'todo_1');
      expect(todo.title, 'Review electricity meter reading');
      expect(todo.isCompleted, false);
      expect(todo.dueDate, isNull);
      expect(todo.completedAt, isNull);
      expect(todo.createdAt, isNotNull);
    });

    test('isDueToday accurately detects today dates', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 14, 30);
      final tomorrow = now.add(const Duration(days: 1));
      final yesterday = now.subtract(const Duration(days: 1));

      final todoToday = PersonalTodoModel(
        id: '1',
        title: 'Call plumber',
        dueDate: today,
      );
      final todoTomorrow = PersonalTodoModel(
        id: '2',
        title: 'Submit taxes',
        dueDate: tomorrow,
      );
      final todoYesterday = PersonalTodoModel(
        id: '3',
        title: 'Check pantry',
        dueDate: yesterday,
      );
      final todoNoDue = PersonalTodoModel(
        id: '4',
        title: 'Clean office',
      );

      expect(todoToday.isDueToday, true);
      expect(todoTomorrow.isDueToday, false);
      expect(todoYesterday.isDueToday, false);
      expect(todoNoDue.isDueToday, false);
    });

    test('isOverdue accurately identifies overdue incomplete tasks', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 2));
      final tomorrow = now.add(const Duration(days: 1));

      final overdueTodo = PersonalTodoModel(
        id: '1',
        title: 'Sign vendor contracts',
        dueDate: yesterday,
        isCompleted: false,
      );
      final completedOverdueTodo = PersonalTodoModel(
        id: '2',
        title: 'Pay generator diesel',
        dueDate: yesterday,
        isCompleted: true,
      );
      final futureTodo = PersonalTodoModel(
        id: '3',
        title: 'Warden meeting',
        dueDate: tomorrow,
        isCompleted: false,
      );
      final noDueTodo = PersonalTodoModel(
        id: '4',
        title: 'Review leaves',
        isCompleted: false,
      );

      expect(overdueTodo.isOverdue, true);
      expect(completedOverdueTodo.isOverdue, false);
      expect(futureTodo.isOverdue, false);
      expect(noDueTodo.isOverdue, false);
    });

    test('toMap converts model to expected map representation', () {
      final created = DateTime(2026, 9, 7, 10, 0);
      final due = DateTime(2026, 9, 10, 18, 0);
      final completed = DateTime(2026, 9, 8, 12, 0);

      final todo = PersonalTodoModel(
        id: 'todo_99',
        title: 'Renew CCTV subscription',
        isCompleted: true,
        dueDate: due,
        createdAt: created,
        completedAt: completed,
      );

      final map = todo.toMap();
      expect(map['title'], 'Renew CCTV subscription');
      expect(map['isCompleted'], true);
      expect(map['dueDate'], isNotNull);
      expect(map['createdAt'], isNotNull);
      expect(map['completedAt'], isNotNull);
      expect(map['updatedAt'], isNotNull);
    });

    test('copyWith properly updates fields while preserving others', () {
      final todo = PersonalTodoModel(
        id: 'todo_orig',
        title: 'Original Title',
        isCompleted: false,
      );

      final updated = todo.copyWith(
        title: 'Updated Title',
        isCompleted: true,
      );

      expect(updated.id, 'todo_orig');
      expect(updated.title, 'Updated Title');
      expect(updated.isCompleted, true);
      expect(todo.title, 'Original Title');
      expect(todo.isCompleted, false);
    });
  });
}
