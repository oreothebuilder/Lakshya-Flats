enum MealType { breakfast, lunch, snacks, dinner }

class MealInfo {
  final MealType type;
  final String title;
  String timeSlot;
  final String icon;
  List<String> items;

  MealInfo({
    required this.type,
    required this.title,
    required this.timeSlot,
    required this.icon,
    required this.items,
  });

  MealInfo copyWith({
    MealType? type,
    String? title,
    String? timeSlot,
    String? icon,
    List<String>? items,
  }) {
    return MealInfo(
      type: type ?? this.type,
      title: title ?? this.title,
      timeSlot: timeSlot ?? this.timeSlot,
      icon: icon ?? this.icon,
      items: items != null ? List<String>.from(items) : List<String>.from(this.items),
    );
  }
}

class DayMenu {
  final String dayName;
  final String shortDay;
  final List<MealInfo> meals;

  DayMenu({
    required this.dayName,
    required this.shortDay,
    required this.meals,
  });

  DayMenu copyWith({
    String? dayName,
    String? shortDay,
    List<MealInfo>? meals,
  }) {
    return DayMenu(
      dayName: dayName ?? this.dayName,
      shortDay: shortDay ?? this.shortDay,
      meals: meals != null ? meals.map((m) => m.copyWith()).toList() : this.meals.map((m) => m.copyWith()).toList(),
    );
  }
}

class MessSchedule {
  final String messName;
  final List<DayMenu> days;

  MessSchedule({
    required this.messName,
    required this.days,
  });
}
