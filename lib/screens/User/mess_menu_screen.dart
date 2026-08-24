import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/user_drawer.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class MessMenuScreen extends StatefulWidget {
  const MessMenuScreen({super.key});

  @override
  State<MessMenuScreen> createState() => _MessMenuScreenState();
}

class _MessMenuScreenState extends State<MessMenuScreen> {
  String _selectedDay = "Monday";

  final List<String> _days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

  // Dummy menu database structured by day
  final Map<String, List<Map<String, String>>> _menuData = {
    "Monday": [
      {
        "emoji": "🌅",
        "type": "Breakfast",
        "time": "07:30 AM - 09:30 AM",
        "items": "Indori Poha, Sev, Jalebi, Masala Tea"
      },
      {
        "emoji": "☀️",
        "type": "Lunch",
        "time": "12:30 PM - 02:30 PM",
        "items": "Paneer Butter Masala, Dal Fry, Phulka, Rice, Salad"
      },
      {
        "emoji": "☕",
        "type": "Evening Snacks",
        "time": "05:00 PM - 06:00 PM",
        "items": "Veg Sandwich, Tea"
      },
      {
        "emoji": "🌙",
        "type": "Dinner",
        "time": "07:30 PM - 09:30 PM",
        "items": "Aloo Matar, Yellow Dal, Chapati, Rice, Kheer"
      },
    ],
    "Tuesday": [
      {
        "emoji": "🌅",
        "type": "Breakfast",
        "time": "07:30 AM - 09:30 AM",
        "items": "Idli Sambhar, Coconut Chutney, Filter Coffee"
      },
      {
        "emoji": "☀️",
        "type": "Lunch",
        "time": "12:30 PM - 02:30 PM",
        "items": "Chole, Bhature, Onion Salad, Boondi Raita"
      },
      {
        "emoji": "☕",
        "type": "Evening Snacks",
        "time": "05:00 PM - 06:00 PM",
        "items": "Samosa, Mint Chutney, Masala Chai"
      },
      {
        "emoji": "🌙",
        "type": "Dinner",
        "time": "07:30 PM - 09:30 PM",
        "items": "Paneer Butter Masala, Dal Fry, Roti, Jeera Rice, Gulab Jamun"
      },
    ],
    "Wednesday": [
      {
        "emoji": "🌅",
        "type": "Breakfast",
        "time": "07:30 AM - 09:30 AM",
        "items": "Methi Paratha, White Butter, Tea"
      },
      {
        "emoji": "☀️",
        "type": "Lunch",
        "time": "12:30 PM - 02:30 PM",
        "items": "Dal Tadka, Mix Veg Sabzi, Rice, Roti, Salad"
      },
      {
        "emoji": "☕",
        "type": "Evening Snacks",
        "time": "05:00 PM - 06:00 PM",
        "items": "Bhel Puri, Mint Lemonade"
      },
      {
        "emoji": "🌙",
        "type": "Dinner",
        "time": "07:30 PM - 09:30 PM",
        "items": "Aloo Gobi, Moong Dal, Phulka, Rice, Kheer"
      },
    ],
    "Thursday": [
      {
        "emoji": "🌅",
        "type": "Breakfast",
        "time": "07:30 AM - 09:30 AM",
        "items": "Aloo Paratha, Curd, Pickle, Tea"
      },
      {
        "emoji": "☀️",
        "type": "Lunch",
        "time": "12:30 PM - 02:30 PM",
        "items": "Rajma Masala, Steamed Rice, Roti, Curd, Papad"
      },
      {
        "emoji": "☕",
        "type": "Evening Snacks",
        "time": "05:00 PM - 06:00 PM",
        "items": "Kachori, Tea"
      },
      {
        "emoji": "🌙",
        "type": "Dinner",
        "time": "07:30 PM - 09:30 PM",
        "items": "Kadahi Paneer, Butter Naan, Rice, Custard"
      },
    ],
    "Friday": [
      {
        "emoji": "🌅",
        "type": "Breakfast",
        "time": "07:30 AM - 09:30 AM",
        "items": "Bread Pakoda, Green Chutney, Tea"
      },
      {
        "emoji": "☀️",
        "type": "Lunch",
        "time": "12:30 PM - 02:30 PM",
        "items": "Veg Pulao, Kadhi Pakoda, Roti, Aloo Jeera"
      },
      {
        "emoji": "☕",
        "type": "Evening Snacks",
        "time": "05:00 PM - 06:00 PM",
        "items": "Pav Bhaji, Tea"
      },
      {
        "emoji": "🌙",
        "type": "Dinner",
        "time": "07:30 PM - 09:30 PM",
        "items": "Dal Makhani, Mix Veg, Phulka, Rice, Ice Cream"
      },
    ],
    "Saturday": [
      {
        "emoji": "🌅",
        "type": "Breakfast",
        "time": "07:30 AM - 09:30 AM",
        "items": "Upma, Coconut Chutney, Tea"
      },
      {
        "emoji": "☀️",
        "type": "Lunch",
        "time": "12:30 PM - 02:30 PM",
        "items": "Alu Shimla Mirch, Yellow Dal, Roti, Rice, Curd"
      },
      {
        "emoji": "☕",
        "type": "Evening Snacks",
        "time": "05:00 PM - 06:00 PM",
        "items": "Aloo Tikki Chaat, Tea"
      },
      {
        "emoji": "🌙",
        "type": "Dinner",
        "time": "07:30 PM - 09:30 PM",
        "items": "Matar Paneer, Tandoori Roti, Rice, Gulab Jamun"
      },
    ],
    "Sunday": [
      {
        "emoji": "🌅",
        "type": "Breakfast",
        "time": "07:30 AM - 09:30 AM",
        "items": "Puri Bhaji, Halwa, Tea"
      },
      {
        "emoji": "☀️",
        "type": "Lunch",
        "time": "12:30 PM - 02:30 PM",
        "items": "Special Veg Biryani, Mirchi Ka Salan, Raita"
      },
      {
        "emoji": "☕",
        "type": "Evening Snacks",
        "time": "05:00 PM - 06:00 PM",
        "items": "French Fries, Cold Drink"
      },
      {
        "emoji": "🌙",
        "type": "Dinner",
        "time": "07:30 PM - 09:30 PM",
        "items": "Paneer Lababdar, Dal Tadka, Missi Roti, Rice, Rabdi"
      },
    ]
  };



  @override
  Widget build(BuildContext context) {
    final selectedMeals = _menuData[_selectedDay] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const UserDrawer(activeItem: "Mess Menu"),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.home_outlined,
                color: Color(0xFF1A65D6),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mess Menu & Timings",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  "Lakshya • Rm 304",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF475569)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    "2",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16, left: 4),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  "SU",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blue Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Mess Menu Schedule",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Lakshya Mess",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "TODAY",
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Select Day Section Title
              Text(
                "Select Day of Week",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 14),

              // Days Row Horizontal Scroller
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _days.length,
                  itemBuilder: (context, index) {
                    final day = _days[index];
                    final isSelected = day == _selectedDay;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDay = day;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              day,
                              style: GoogleFonts.plusJakartaSans(
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                                fontSize: 14.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Meals List View
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedMeals.length,
                itemBuilder: (context, index) {
                  final meal = selectedMeals[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF1F5F9),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  meal["emoji"] ?? "🍽️",
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  meal["type"] ?? "",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                meal["time"] ?? "",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          color: Color(0xFFF1F5F9),
                          height: 24,
                          thickness: 1,
                        ),
                        Text(
                          meal["items"] ?? "",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
