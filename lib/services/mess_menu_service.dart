import 'package:flutter/foundation.dart';
import '../models/mess_menu_model.dart';

class MessMenuService extends ChangeNotifier {
  static final MessMenuService _instance = MessMenuService._internal();
  factory MessMenuService() => _instance;

  late Map<String, MessSchedule> _schedules;

  MessMenuService._internal() {
    _initDefaultSchedules();
  }

  Map<String, MessSchedule> get schedules => _schedules;

  List<String> get availableMesses => ["Univ Homes", "Rameshwaram", "Shivalay"];

  MessSchedule? getSchedule(String messName) {
    return _schedules[messName];
  }

  DayMenu? getDayMenu(String messName, String shortDay) {
    final schedule = _schedules[messName];
    if (schedule == null) return null;
    return schedule.days.firstWhere(
      (d) => d.shortDay.toLowerCase() == shortDay.toLowerCase(),
      orElse: () => schedule.days.first,
    );
  }

  void updateMealItems(String messName, String shortDay, MealType type, List<String> newItems) {
    final dayMenu = getDayMenu(messName, shortDay);
    if (dayMenu != null) {
      final meal = dayMenu.meals.firstWhere((m) => m.type == type);
      meal.items = List<String>.from(newItems);
      notifyListeners();
    }
  }

  void updateMealTimeSlot(String messName, String shortDay, MealType type, String newTimeSlot) {
    final dayMenu = getDayMenu(messName, shortDay);
    if (dayMenu != null) {
      final meal = dayMenu.meals.firstWhere((m) => m.type == type);
      meal.timeSlot = newTimeSlot;
      notifyListeners();
    }
  }

  void addMealItem(String messName, String shortDay, MealType type, String item) {
    final dayMenu = getDayMenu(messName, shortDay);
    if (dayMenu != null) {
      final meal = dayMenu.meals.firstWhere((m) => m.type == type);
      if (!meal.items.contains(item)) {
        meal.items.add(item);
        notifyListeners();
      }
    }
  }

  void removeMealItem(String messName, String shortDay, MealType type, String item) {
    final dayMenu = getDayMenu(messName, shortDay);
    if (dayMenu != null) {
      final meal = dayMenu.meals.firstWhere((m) => m.type == type);
      meal.items.remove(item);
      notifyListeners();
    }
  }

  void _initDefaultSchedules() {
    final daysList = [
      {"name": "Monday", "short": "Mon"},
      {"name": "Tuesday", "short": "Tue"},
      {"name": "Wednesday", "short": "Wed"},
      {"name": "Thursday", "short": "Thu"},
      {"name": "Friday", "short": "Fri"},
      {"name": "Saturday", "short": "Sat"},
      {"name": "Sunday", "short": "Sun"},
    ];

    // Default menus for Univ Homes
    final univHomesDays = daysList.map((d) {
      final isMon = d["short"] == "Mon";
      final isSun = d["short"] == "Sun";
      return DayMenu(
        dayName: d["name"]!,
        shortDay: d["short"]!,
        meals: [
          MealInfo(
            type: MealType.breakfast,
            title: "Breakfast",
            timeSlot: "07:30 AM - 09:30 AM",
            icon: "🌅",
            items: isMon
                ? ["Indori Poha", "Sev", "Jalebi", "Masala Tea"]
                : isSun
                    ? ["Chole Bhature", "Lassi", "Sweet Chutney"]
                    : ["Alo Paratha", "Curd", "Pickle", "Tea"],
          ),
          MealInfo(
            type: MealType.lunch,
            title: "Lunch",
            timeSlot: "12:30 PM - 02:30 PM",
            icon: "☀️",
            items: isMon
                ? ["Paneer Butter Masala", "Dal Fry", "Phulka", "Rice", "Salad"]
                : isSun
                    ? ["Special Veg Biryani", "Mirchi Ka Salan", "Raita", "Gulab Jamun"]
                    : ["Rajma Masala", "Jeera Rice", "Roti", "Salad", "Papad"],
          ),
          MealInfo(
            type: MealType.snacks,
            title: "Evening Snacks",
            timeSlot: "05:00 PM - 06:00 PM",
            icon: "☕",
            items: isMon
                ? ["Veg Sandwich", "Tea"]
                : ["Samosa", "Mint Chutney", "Coffee"],
          ),
          MealInfo(
            type: MealType.dinner,
            title: "Dinner",
            timeSlot: "07:30 PM - 09:30 PM",
            icon: "🌙",
            items: isMon
                ? ["Aloo Matar", "Yellow Dal", "Chapati", "Rice", "Kheer"]
                : ["Kadai Paneer", "Dal Makhani", "Butter Naan", "Rice", "Ice Cream"],
          ),
        ],
      );
    }).toList();

    // Default menus for Rameshwaram
    final rameshwaramDays = daysList.map((d) {
      return DayMenu(
        dayName: d["name"]!,
        shortDay: d["short"]!,
        meals: [
          MealInfo(
            type: MealType.breakfast,
            title: "Breakfast",
            timeSlot: "07:30 AM - 09:30 AM",
            icon: "🌅",
            items: ["Idli Sambhar", "Coconut Chutney", "Filter Coffee"],
          ),
          MealInfo(
            type: MealType.lunch,
            title: "Lunch",
            timeSlot: "12:30 PM - 02:30 PM",
            icon: "☀️",
            items: ["Chole", "Bhature", "Onion Salad", "Boondi Raita"],
          ),
          MealInfo(
            type: MealType.snacks,
            title: "Evening Snacks",
            timeSlot: "05:00 PM - 06:00 PM",
            icon: "☕",
            items: ["Samosa", "Mint Chutney", "Masala Chai"],
          ),
          MealInfo(
            type: MealType.dinner,
            title: "Dinner",
            timeSlot: "07:30 PM - 09:30 PM",
            icon: "🌙",
            items: ["Paneer Butter Masala", "Dal Fry", "Roti", "Jeera Rice", "Gulab Jamun"],
          ),
        ],
      );
    }).toList();

    // Default menus for Shivalay
    final shivalayDays = daysList.map((d) {
      return DayMenu(
        dayName: d["name"]!,
        shortDay: d["short"]!,
        meals: [
          MealInfo(
            type: MealType.breakfast,
            title: "Breakfast",
            timeSlot: "07:30 AM - 09:30 AM",
            icon: "🌅",
            items: ["Methi Paratha", "White Butter", "Tea"],
          ),
          MealInfo(
            type: MealType.lunch,
            title: "Lunch",
            timeSlot: "12:30 PM - 02:30 PM",
            icon: "☀️",
            items: ["Dal Tadka", "Mix Veg Sabzi", "Rice", "Roti", "Salad"],
          ),
          MealInfo(
            type: MealType.snacks,
            title: "Evening Snacks",
            timeSlot: "05:00 PM - 06:00 PM",
            icon: "☕",
            items: ["Bhel Puri", "Mint Lemonade"],
          ),
          MealInfo(
            type: MealType.dinner,
            title: "Dinner",
            timeSlot: "07:30 PM - 09:30 PM",
            icon: "🌙",
            items: ["Aloo Gobi", "Moong Dal", "Phulka", "Rice", "Kheer"],
          ),
        ],
      );
    }).toList();

    _schedules = {
      "Univ Homes": MessSchedule(messName: "Univ Homes", days: univHomesDays),
      "Rameshwaram": MessSchedule(messName: "Rameshwaram", days: rameshwaramDays),
      "Shivalay": MessSchedule(messName: "Shivalay", days: shivalayDays),
    };
  }
}
