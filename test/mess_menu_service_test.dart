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

    test('createMess dynamically creates a new mess schedule and adds to availableMesses', () async {
      final initialMessesCount = service.availableMesses.length;
      await service.createMess("Lakshya Grand Mess");

      expect(service.availableMesses, contains("Lakshya Grand Mess"));
      expect(service.availableMesses.length, initialMessesCount + 1);

      final grandMenu = service.getDayMenuByName("Lakshya Grand Mess", "Monday");
      expect(grandMenu, isNotNull);
      expect(grandMenu!.meals.length, 4);
    });

    test('setBuildingMess dynamically maps building to mess and recognizes No Mess', () {
      service.setBuildingMess("Emerald Heights", "Lakshya Grand Mess");
      expect(service.resolveMessForBuilding("Emerald Heights"), "Lakshya Grand Mess");
      expect(service.isBuildingNoMess("Emerald Heights"), isFalse);

      service.setBuildingMess("Diamond Tower", "No Mess");
      expect(service.isBuildingNoMess("Diamond Tower"), isTrue);
    });

    test('Blank meal slots are completely omitted when filtered for customer portal', () {
      // Simulate day menu where evening snack is empty (0 items)
      final dayMenu = DayMenu(
        dayName: "Monday",
        shortDay: "Mon",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "08:00 AM", icon: "🌅", items: ["Poha", "Tea"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "01:00 PM", icon: "🍱", items: ["Dal", "Roti", "Rice"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM", icon: "☕", items: []), // Empty
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "08:00 PM", icon: "🍲", items: ["Paneer", "Roti"]),
        ],
      );

      final activeMeals = dayMenu.meals
          .where((m) => m.items.any((item) => item.trim().isNotEmpty))
          .toList();

      expect(activeMeals.length, 3);
      expect(activeMeals.map((m) => m.type), isNot(contains(MealType.snacks)));
      expect(activeMeals.map((m) => m.title).toList(), ["Breakfast", "Lunch", "Dinner"]);

      // Simulate next day where breakfast is empty
      final nextDayMenu = DayMenu(
        dayName: "Tuesday",
        shortDay: "Tue",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "08:00 AM", icon: "🌅", items: ["   "]), // Whitespace only
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "01:00 PM", icon: "🍱", items: ["Rajma", "Rice"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM", icon: "☕", items: ["Samosa", "Chai"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "08:00 PM", icon: "🍲", items: ["Khichdi"]),
        ],
      );

      final nextActiveMeals = nextDayMenu.meals
          .where((m) => m.items.any((item) => item.trim().isNotEmpty))
          .toList();

      expect(nextActiveMeals.length, 3);
      expect(nextActiveMeals.map((m) => m.type), isNot(contains(MealType.breakfast)));
      expect(nextActiveMeals.map((m) => m.title).toList(), ["Lunch", "Evening Snacks", "Dinner"]);
    });
  });
}
