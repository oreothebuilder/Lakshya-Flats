import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/mess_menu_model.dart';

class MessMenuService extends ChangeNotifier {
  static final MessMenuService _instance = MessMenuService._internal();
  factory MessMenuService() => _instance;

  late Map<String, MessSchedule> _schedules;
  bool _isListening = false;

  MessMenuService._internal() {
    _initDefaultSchedules();
    _listenToFirestore();
  }

  Map<String, MessSchedule> get schedules => _schedules;

  List<String> get availableMesses => ["Univ Homes", "Rameshwaram", "Shivalay"];

  void _listenToFirestore() {
    if (_isListening) return;
    if (Firebase.apps.isEmpty) {
      // Firebase not initialized (e.g. in test environment)
      return;
    }
    _isListening = true;
    try {
      FirebaseFirestore.instance.collection('mess_menus').snapshots().listen((snapshot) {
        if (snapshot.docs.isEmpty) {
          _seedDefaultSchedulesToFirestore();
        } else {
          for (var doc in snapshot.docs) {
            try {
              final schedule = MessSchedule.fromJson(doc.data());
              _schedules[schedule.messName] = schedule;
            } catch (e) {
              debugPrint("Error parsing mess schedule for ${doc.id}: $e");
            }
          }
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint("MessMenuService firestore listen error: $err");
      });
    } catch (e) {
      debugPrint("MessMenuService firestore init error: $e");
    }
  }

  Future<void> _seedDefaultSchedulesToFirestore() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance.collection('mess_menus');
      for (final entry in _schedules.entries) {
        batch.set(collection.doc(entry.key), entry.value.toJson());
      }
      await batch.commit();
      debugPrint("Seeded default mess menus to Firestore.");
    } catch (e) {
      debugPrint("Error seeding mess menus to Firestore: $e");
    }
  }

  Future<void> _saveScheduleToFirestore(String messName) async {
    try {
      final schedule = _schedules[messName];
      if (schedule != null) {
        await FirebaseFirestore.instance
            .collection('mess_menus')
            .doc(messName)
            .set(schedule.toJson());
      }
    } catch (e) {
      debugPrint("Error saving mess schedule to Firestore: $e");
    }
  }

  String getCurrentDayShort() {
    final now = DateTime.now();
    switch (now.weekday) {
      case DateTime.monday:
        return "Mon";
      case DateTime.tuesday:
        return "Tue";
      case DateTime.wednesday:
        return "Wed";
      case DateTime.thursday:
        return "Thu";
      case DateTime.friday:
        return "Fri";
      case DateTime.saturday:
        return "Sat";
      case DateTime.sunday:
        return "Sun";
      default:
        return "Mon";
    }
  }

  String getCurrentDayName() {
    final now = DateTime.now();
    switch (now.weekday) {
      case DateTime.monday:
        return "Monday";
      case DateTime.tuesday:
        return "Tuesday";
      case DateTime.wednesday:
        return "Wednesday";
      case DateTime.thursday:
        return "Thursday";
      case DateTime.friday:
        return "Friday";
      case DateTime.saturday:
        return "Saturday";
      case DateTime.sunday:
        return "Sunday";
      default:
        return "Monday";
    }
  }

  String resolveMessForBuilding(String? building) {
    if (building == null || building.trim().isEmpty) return "Univ Homes";
    final b = building.toLowerCase();
    if (b.contains("rameshwaram")) return "Rameshwaram";
    if (b.contains("shivalay")) return "Shivalay";
    return "Univ Homes";
  }

  MessSchedule? getSchedule(String messName) {
    return _schedules[messName];
  }

  DayMenu? getTodayMenu(String messName) {
    return getDayMenu(messName, getCurrentDayShort());
  }

  DayMenu? getDayMenu(String messName, String shortDay) {
    final schedule = _schedules[messName];
    if (schedule == null) return null;
    return schedule.days.firstWhere(
      (d) => d.shortDay.toLowerCase() == shortDay.toLowerCase(),
      orElse: () => schedule.days.first,
    );
  }

  DayMenu? getDayMenuByName(String messName, String dayNameOrShort) {
    final schedule = _schedules[messName];
    if (schedule == null) return null;
    return schedule.days.firstWhere(
      (d) =>
          d.dayName.toLowerCase() == dayNameOrShort.toLowerCase() ||
          d.shortDay.toLowerCase() == dayNameOrShort.toLowerCase(),
      orElse: () => schedule.days.first,
    );
  }

  void updateMealItems(String messName, String shortDay, MealType type, List<String> newItems) {
    final dayMenu = getDayMenu(messName, shortDay);
    if (dayMenu != null) {
      final meal = dayMenu.meals.firstWhere((m) => m.type == type);
      meal.items = List<String>.from(newItems);
      notifyListeners();
      _saveScheduleToFirestore(messName);
    }
  }

  void updateMealTimeSlot(String messName, String shortDay, MealType type, String newTimeSlot) {
    final dayMenu = getDayMenu(messName, shortDay);
    if (dayMenu != null) {
      final meal = dayMenu.meals.firstWhere((m) => m.type == type);
      meal.timeSlot = newTimeSlot;
      notifyListeners();
      _saveScheduleToFirestore(messName);
    }
  }

  void addMealItem(String messName, String shortDay, MealType type, String item) {
    final dayMenu = getDayMenu(messName, shortDay);
    if (dayMenu != null) {
      final meal = dayMenu.meals.firstWhere((m) => m.type == type);
      if (!meal.items.contains(item)) {
        meal.items.add(item);
        notifyListeners();
        _saveScheduleToFirestore(messName);
      }
    }
  }

  void removeMealItem(String messName, String shortDay, MealType type, String item) {
    final dayMenu = getDayMenu(messName, shortDay);
    if (dayMenu != null) {
      final meal = dayMenu.meals.firstWhere((m) => m.type == type);
      meal.items.remove(item);
      notifyListeners();
      _saveScheduleToFirestore(messName);
    }
  }

  void _initDefaultSchedules() {
    // 7 Days Menu for Univ Homes
    final univHomesDays = [
      DayMenu(
        dayName: "Monday",
        shortDay: "Mon",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Indori Poha", "Sev", "Jalebi", "Masala Tea"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Paneer Butter Masala", "Dal Fry", "Phulka", "Rice", "Salad"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Veg Sandwich", "Tea"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Aloo Matar", "Yellow Dal", "Chapati", "Rice", "Kheer"]),
        ],
      ),
      DayMenu(
        dayName: "Tuesday",
        shortDay: "Tue",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Idli Sambhar", "Coconut Chutney", "Filter Coffee"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Chole", "Bhature", "Onion Salad", "Boondi Raita"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Samosa", "Mint Chutney", "Masala Chai"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Paneer Butter Masala", "Dal Fry", "Roti", "Jeera Rice", "Gulab Jamun"]),
        ],
      ),
      DayMenu(
        dayName: "Wednesday",
        shortDay: "Wed",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Methi Paratha", "White Butter", "Tea"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Dal Tadka", "Mix Veg Sabzi", "Rice", "Roti", "Salad"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Bhel Puri", "Mint Lemonade"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Aloo Gobi", "Moong Dal", "Phulka", "Rice", "Kheer"]),
        ],
      ),
      DayMenu(
        dayName: "Thursday",
        shortDay: "Thu",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Aloo Paratha", "Curd", "Pickle", "Tea"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Rajma Masala", "Steamed Rice", "Roti", "Curd", "Papad"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Kachori", "Tea"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Kadai Paneer", "Butter Naan", "Rice", "Custard"]),
        ],
      ),
      DayMenu(
        dayName: "Friday",
        shortDay: "Fri",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Bread Pakoda", "Green Chutney", "Tea"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Veg Pulao", "Kadhi Pakoda", "Roti", "Aloo Jeera"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Pav Bhaji", "Tea"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Dal Makhani", "Mix Veg", "Phulka", "Rice", "Ice Cream"]),
        ],
      ),
      DayMenu(
        dayName: "Saturday",
        shortDay: "Sat",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Upma", "Coconut Chutney", "Tea"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Alu Shimla Mirch", "Yellow Dal", "Roti", "Rice", "Curd"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Aloo Tikki Chaat", "Tea"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Matar Paneer", "Tandoori Roti", "Rice", "Gulab Jamun"]),
        ],
      ),
      DayMenu(
        dayName: "Sunday",
        shortDay: "Sun",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Puri Bhaji", "Halwa", "Tea"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Special Veg Biryani", "Mirchi Ka Salan", "Raita"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["French Fries", "Cold Drink"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Paneer Lababdar", "Dal Tadka", "Missi Roti", "Rice", "Rabdi"]),
        ],
      ),
    ];

    // 7 Days Menu for Rameshwaram
    final rameshwaramDays = [
      DayMenu(
        dayName: "Monday",
        shortDay: "Mon",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Idli Sambhar", "Coconut Chutney", "Filter Coffee"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Chole", "Bhature", "Onion Salad", "Boondi Raita"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Samosa", "Mint Chutney", "Masala Chai"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Paneer Butter Masala", "Dal Fry", "Roti", "Jeera Rice", "Gulab Jamun"]),
        ],
      ),
      DayMenu(
        dayName: "Tuesday",
        shortDay: "Tue",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Masala Dosa", "Tomato Chutney", "Sambhar", "Filter Coffee"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Rajma Masala", "Jeera Rice", "Phulka", "Cucumber Salad"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Medu Vada", "Coconut Chutney", "Tea"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Mix Veg Curry", "Dal Tadka", "Roti", "Rice", "Fruit Custard"]),
        ],
      ),
      DayMenu(
        dayName: "Wednesday",
        shortDay: "Wed",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Poha", "Sev", "Roasted Peanuts", "Adrak Chai"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Paneer Do Pyaza", "Dal Makhani", "Tandoori Roti", "Rice"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Veg Cutlet", "Tomato Ketchup", "Coffee"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Aloo Gobi", "Yellow Dal", "Phulka", "Rice", "Halwa"]),
        ],
      ),
      DayMenu(
        dayName: "Thursday",
        shortDay: "Thu",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Uttapam", "Coconut & Mint Chutney", "Sambhar"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Kadi Pakoda", "Steamed Rice", "Aloo Bhindi", "Phulka"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Mirchi Bajji", "Masala Tea"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Shahi Paneer", "Butter Roti", "Jeera Rice", "Rasgulla"]),
        ],
      ),
      DayMenu(
        dayName: "Friday",
        shortDay: "Fri",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Mysore Bonda", "Coconut Chutney", "Tea"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Veg Biryani", "Mirchi Ka Salan", "Onion Raita", "Papad"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Onion Pakoda", "Green Chutney", "Coffee"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Dum Aloo Kashmiri", "Dal Fry", "Phulka", "Rice", "Kheer"]),
        ],
      ),
      DayMenu(
        dayName: "Saturday",
        shortDay: "Sat",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Rava Upma", "Podi", "Coconut Chutney", "Tea"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Chana Masala", "Poori", "Boondi Raita", "Salad"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Pani Puri", "Sweet Chutney"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Kadai Veg", "Dal Tadka", "Naan", "Rice", "Ice Cream"]),
        ],
      ),
      DayMenu(
        dayName: "Sunday",
        shortDay: "Sun",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Puri Saagu", "Sheera (Kesari Bath)", "Filter Coffee"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Special Hyderabadi Veg Biryani", "Salan", "Raita", "Gulab Jamun"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Paneer Bread Roll", "Chai"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Paneer Makhani", "Butter Naan", "Veg Pulao", "Moong Dal Halwa"]),
        ],
      ),
    ];

    // 7 Days Menu for Shivalay
    final shivalayDays = [
      DayMenu(
        dayName: "Monday",
        shortDay: "Mon",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Methi Paratha", "White Butter", "Tea"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Dal Tadka", "Mix Veg Sabzi", "Rice", "Roti", "Salad"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Bhel Puri", "Mint Lemonade"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Aloo Gobi", "Moong Dal", "Phulka", "Rice", "Kheer"]),
        ],
      ),
      DayMenu(
        dayName: "Tuesday",
        shortDay: "Tue",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Poha Jalebi", "Sev", "Masala Chai"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Paneer Bhurji", "Dal Fry", "Phulka", "Rice", "Papad"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Veg Puff", "Tea"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Baingan Bharta", "Tawa Roti", "Dal Tadka", "Rice", "Fruit Cream"]),
        ],
      ),
      DayMenu(
        dayName: "Wednesday",
        shortDay: "Wed",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Gobi Paratha", "Curd", "Mixed Pickle", "Tea"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Rajma Chawal", "Boondi Raita", "Onion Salad", "Roti"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Sev Puri", "Mint Chai"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Matar Paneer", "Dal Makhani", "Phulka", "Jeera Rice", "Gulab Jamun"]),
        ],
      ),
      DayMenu(
        dayName: "Thursday",
        shortDay: "Thu",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Bedmi Puri", "Aloo Sabzi", "Tea"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Malai Kofta", "Butter Roti", "Rice", "Cucumber Raita"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Samosa Chaat", "Green Tea"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Bhindi Masala", "Yellow Moong Dal", "Phulka", "Rice", "Seviyan Kheer"]),
        ],
      ),
      DayMenu(
        dayName: "Friday",
        shortDay: "Fri",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Moong Dal Chilla", "Mint Chutney", "Tea"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Chole Kulche", "Pickled Onions", "Chaas"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Dhokla", "Sweet Tamarind Chutney", "Tea"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Paneer Pasanda", "Dal Fry", "Phulka", "Peas Pulao", "Rasmalai"]),
        ],
      ),
      DayMenu(
        dayName: "Saturday",
        shortDay: "Sat",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Aloo Paratha", "Curd", "Homemade White Butter", "Tea"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Kadhi Khichdi", "Gujarati Aloo", "Papad", "Curd"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["French Fries", "Hot Coffee"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Mix Veg Korma", "Dal Tadka", "Tandoori Roti", "Rice", "Shahi Tukda"]),
        ],
      ),
      DayMenu(
        dayName: "Sunday",
        shortDay: "Sun",
        meals: [
          MealInfo(type: MealType.breakfast, title: "Breakfast", timeSlot: "07:30 AM - 09:30 AM", icon: "🌅", items: ["Chole Bhature", "Sweet Lassi", "Pickle"]),
          MealInfo(type: MealType.lunch, title: "Lunch", timeSlot: "12:30 PM - 02:30 PM", icon: "☀️", items: ["Kashmiri Pulao", "Paneer Tikka Masala", "Butter Naan", "Raita"]),
          MealInfo(type: MealType.snacks, title: "Evening Snacks", timeSlot: "05:00 PM - 06:00 PM", icon: "☕", items: ["Cheese Grilled Sandwich", "Cold Coffee"]),
          MealInfo(type: MealType.dinner, title: "Dinner", timeSlot: "07:30 PM - 09:30 PM", icon: "🌙", items: ["Palak Paneer", "Dal Makhani", "Missi Roti", "Rice", "Gajar Ka Halwa"]),
        ],
      ),
    ];

    _schedules = {
      "Univ Homes": MessSchedule(messName: "Univ Homes", days: univHomesDays),
      "Rameshwaram": MessSchedule(messName: "Rameshwaram", days: rameshwaramDays),
      "Shivalay": MessSchedule(messName: "Shivalay", days: shivalayDays),
    };
  }
}
