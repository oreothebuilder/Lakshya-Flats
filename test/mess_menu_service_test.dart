import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_residency/services/mess_menu_service.dart';
import 'package:lakshya_residency/models/mess_menu_model.dart';

void main() {
  group('MessMenuService Tests', () {
    late MessMenuService service;

    setUp(() {
      service = MessMenuService();
    });

    test('Returns current day short and full names accurately based on DateTime.now', () {
      final now = DateTime.now();
      final dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
      final dayShorts = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

      expect(service.getCurrentDayName(), dayNames[now.weekday - 1]);
      expect(service.getCurrentDayShort(), dayShorts[now.weekday - 1]);
    });

    test('getTodayMenu returns DayMenu matching today for all messes with 4 meals', () {
      for (final mess in service.availableMesses) {
        final todayMenu = service.getTodayMenu(mess);
        expect(todayMenu, isNotNull);
        expect(todayMenu!.shortDay.toLowerCase(), service.getCurrentDayShort().toLowerCase());
        expect(todayMenu.meals.length, 4);

        final mealTypes = todayMenu.meals.map((m) => m.type).toList();
        expect(mealTypes, containsAll([
          MealType.breakfast,
          MealType.lunch,
          MealType.snacks,
          MealType.dinner,
        ]));

        for (final meal in todayMenu.meals) {
          expect(meal.items, isNotEmpty);
          expect(meal.timeSlot, isNotEmpty);
        }
      }
    });

    test('resolveMessForBuilding resolves buildings accurately with defaults', () {
      expect(service.resolveMessForBuilding("Rameshwaram Residency"), "Rameshwaram");
      expect(service.resolveMessForBuilding("Shivalay Hostel"), "Shivalay");
      expect(service.resolveMessForBuilding("Univ Homes"), "Univ Homes");
      expect(service.resolveMessForBuilding("Lakshya Prime"), "Univ Homes");
      expect(service.resolveMessForBuilding(null), "Univ Homes");
      expect(service.resolveMessForBuilding(""), "Univ Homes");
    });

    test('getDayMenuByName retrieves the expected day menu', () {
      final monMenu = service.getDayMenuByName("Univ Homes", "Monday");
      expect(monMenu, isNotNull);
      expect(monMenu!.shortDay, "Mon");

      final sunMenu = service.getDayMenuByName("Univ Homes", "Sun");
      expect(sunMenu, isNotNull);
      expect(sunMenu!.dayName, "Sunday");
    });
  });
}
