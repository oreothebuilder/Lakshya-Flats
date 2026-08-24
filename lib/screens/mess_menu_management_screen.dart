import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mess_menu_model.dart';
import '../services/mess_menu_service.dart';

class MessMenuManagementScreen extends StatefulWidget {
  final String initialMess;
  final bool isAdmin;

  const MessMenuManagementScreen({
    super.key,
    this.initialMess = "Univ Homes",
    this.isAdmin = true,
  });

  @override
  State<MessMenuManagementScreen> createState() => _MessMenuManagementScreenState();
}

class _MessMenuManagementScreenState extends State<MessMenuManagementScreen> {
  late String _selectedMess;
  late String _selectedDayShort;
  final MessMenuService _menuService = MessMenuService();

  final List<Map<String, String>> _days = [
    {"short": "Mon", "full": "Monday"},
    {"short": "Tue", "full": "Tuesday"},
    {"short": "Wed", "full": "Wednesday"},
    {"short": "Thu", "full": "Thursday"},
    {"short": "Fri", "full": "Friday"},
    {"short": "Sat", "full": "Saturday"},
    {"short": "Sun", "full": "Sunday"},
  ];

  @override
  void initState() {
    super.initState();
    _selectedMess = widget.initialMess;
    _selectedDayShort = _getCurrentDayShort();
    _menuService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _menuService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  String _getCurrentDayShort() {
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

  bool _isToday(String dayShort) {
    return dayShort.toLowerCase() == _getCurrentDayShort().toLowerCase();
  }

  String _getFullDayName(String dayShort) {
    final match = _days.firstWhere(
      (d) => d["short"]!.toLowerCase() == dayShort.toLowerCase(),
      orElse: () => {"short": "Mon", "full": "Monday"},
    );
    return match["full"]!;
  }

  @override
  Widget build(BuildContext context) {
    final dayMenu = _menuService.getDayMenu(_selectedMess, _selectedDayShort);
    final fullDayName = _getFullDayName(_selectedDayShort);
    final isCurrentDay = _isToday(_selectedDayShort);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Mess Menu Management",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Weekly Schedule & Building Meals",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF0F172A)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Select Hostel Building Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "SELECT HOSTEL BUILDING",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Hostel Building Filter Chips
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _menuService.availableMesses.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final messName = _menuService.availableMesses[index];
                  final isSelected = messName == _selectedMess;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMess = messName;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0056D2) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0056D2).withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.check_rounded, size: 16, color: Color(0xFF0056D2)),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            messName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? const Color(0xFF0056D2) : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Days of the Week Selector Row
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _days.map((dayMap) {
                  final short = dayMap["short"]!;
                  final isSelected = short == _selectedDayShort;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDayShort = short;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 14 : 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0056D2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            short,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Info Banner Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.sync_rounded,
                        color: Color(0xFF1D4ED8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Weekly Fixed Schedule ($_selectedMess)",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "The mess menu is fixed for the whole week and repeats every week. Edits apply automatically.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF1E3A8A),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Menu Header Row (Monday Menu, TODAY, Edit Menu)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "$fullDayName Menu",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      if (isCurrentDay) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "TODAY",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (widget.isAdmin)
                    ElevatedButton.icon(
                      onPressed: () => _openBulkEditModal(context, dayMenu),
                      icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                      label: Text(
                        "Edit Menu",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0056D2),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Meals List Cards (Breakfast, Lunch, Evening Snacks, Dinner)
            if (dayMenu != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: dayMenu.meals.map((meal) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildMealCard(meal),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(MealInfo meal) {
    Color headerBg;
    Color textColor;
    Color timeColor;

    switch (meal.type) {
      case MealType.breakfast:
        headerBg = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFEA580C);
        timeColor = const Color(0xFFEA580C);
        break;
      case MealType.lunch:
        headerBg = const Color(0xFFF0F9FF);
        textColor = const Color(0xFF0284C7);
        timeColor = const Color(0xFF0284C7);
        break;
      case MealType.snacks:
        headerBg = const Color(0xFFFAF5FF);
        textColor = const Color(0xFF9333EA);
        timeColor = const Color(0xFF9333EA);
        break;
      case MealType.dinner:
        headerBg = const Color(0xFFEEF2FF);
        textColor = const Color(0xFF4F46E5);
        timeColor = const Color(0xFF4F46E5);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      meal.icon,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      meal.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: timeColor),
                    const SizedBox(width: 4),
                    Text(
                      meal.timeSlot,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: timeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items Chips Container
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              children: meal.items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.restaurant_menu_rounded,
                        size: 13,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      if (widget.isAdmin) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            _menuService.removeMealItem(
                              _selectedMess,
                              _selectedDayShort,
                              meal.type,
                              item,
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: 2),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _openBulkEditModal(BuildContext context, DayMenu? dayMenu) {
    if (dayMenu == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _EditMessMenuBottomSheet(
          messName: _selectedMess,
          dayShort: _selectedDayShort,
          dayMenu: dayMenu,
          menuService: _menuService,
        );
      },
    );
  }
}

class _EditMessMenuBottomSheet extends StatefulWidget {
  final String messName;
  final String dayShort;
  final DayMenu dayMenu;
  final MessMenuService menuService;

  const _EditMessMenuBottomSheet({
    required this.messName,
    required this.dayShort,
    required this.dayMenu,
    required this.menuService,
  });

  @override
  State<_EditMessMenuBottomSheet> createState() => _EditMessMenuBottomSheetState();
}

class _EditMessMenuBottomSheetState extends State<_EditMessMenuBottomSheet> {
  late Map<MealType, TextEditingController> _timeControllers;
  late Map<MealType, TextEditingController> _addItemControllers;
  late Map<MealType, List<String>> _mealItems;

  @override
  void initState() {
    super.initState();
    _timeControllers = {};
    _addItemControllers = {};
    _mealItems = {};

    for (var meal in widget.dayMenu.meals) {
      _timeControllers[meal.type] = TextEditingController(text: meal.timeSlot);
      _addItemControllers[meal.type] = TextEditingController();
      _mealItems[meal.type] = List<String>.from(meal.items);
    }
  }

  @override
  void dispose() {
    for (var controller in _timeControllers.values) {
      controller.dispose();
    }
    for (var controller in _addItemControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveChanges() {
    for (var meal in widget.dayMenu.meals) {
      final newTime = _timeControllers[meal.type]?.text.trim() ?? meal.timeSlot;
      final newItems = _mealItems[meal.type] ?? meal.items;

      widget.menuService.updateMealTimeSlot(
        widget.messName,
        widget.dayShort,
        meal.type,
        newTime,
      );
      widget.menuService.updateMealItems(
        widget.messName,
        widget.dayShort,
        meal.type,
        newItems,
      );
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Mess Menu updated successfully for ${widget.messName}!",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Edit ${widget.dayMenu.dayName} Menu",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "Updating menu for ${widget.messName}",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Edit Form for 4 Meals
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: widget.dayMenu.meals.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final meal = widget.dayMenu.meals[index];
                final items = _mealItems[meal.type]!;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meal Title & Time Edit
                      Row(
                        children: [
                          Text(meal.icon, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            meal.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 170,
                            height: 38,
                            child: TextField(
                              controller: _timeControllers[meal.type],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                labelText: "Meal Time",
                                labelStyle: const TextStyle(fontSize: 11),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Existing Items Chips with remove button
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: items.map((item) {
                          return Chip(
                            label: Text(
                              item,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () {
                              setState(() {
                                items.remove(item);
                              });
                            },
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),

                      // Add Item Text Field
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: TextField(
                                controller: _addItemControllers[meal.type],
                                style: GoogleFonts.plusJakartaSans(fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: "Add dish (e.g. Butter Roti)",
                                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final text = _addItemControllers[meal.type]?.text.trim() ?? "";
                              if (text.isNotEmpty && !items.contains(text)) {
                                setState(() {
                                  items.add(text);
                                  _addItemControllers[meal.type]?.clear();
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0056D2),
                              minimumSize: const Size(60, 38),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Add",
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Save / Cancel Actions Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0056D2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      "Save Menu",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
