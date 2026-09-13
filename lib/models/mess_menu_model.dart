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

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'title': title,
      'timeSlot': timeSlot,
      'icon': icon,
      'items': items,
    };
  }

  factory MealInfo.fromJson(Map<String, dynamic> json) {
    MealType resolveType(String? name) {
      switch ((name ?? '').toLowerCase()) {
        case 'breakfast':
          return MealType.breakfast;
        case 'lunch':
          return MealType.lunch;
        case 'snacks':
          return MealType.snacks;
        case 'dinner':
          return MealType.dinner;
        default:
          return MealType.breakfast;
      }
    }

    return MealInfo(
      type: resolveType(json['type']?.toString()),
      title: json['title']?.toString() ?? '',
      timeSlot: json['timeSlot']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '🍽️',
      items: (json['items'] as List?)?.map((e) => e.toString()).toList() ?? [],
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

  Map<String, dynamic> toJson() {
    return {
      'dayName': dayName,
      'shortDay': shortDay,
      'meals': meals.map((m) => m.toJson()).toList(),
    };
  }

  factory DayMenu.fromJson(Map<String, dynamic> json) {
    return DayMenu(
      dayName: json['dayName']?.toString() ?? '',
      shortDay: json['shortDay']?.toString() ?? '',
      meals: (json['meals'] as List?)
              ?.map((e) => MealInfo.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
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

  Map<String, dynamic> toJson() {
    return {
      'messName': messName,
      'days': days.map((d) => d.toJson()).toList(),
    };
  }

  factory MessSchedule.fromJson(Map<String, dynamic> json) {
    return MessSchedule(
      messName: json['messName']?.toString() ?? '',
      days: (json['days'] as List?)
              ?.map((e) => DayMenu.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }
}

