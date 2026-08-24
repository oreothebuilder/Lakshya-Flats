import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/user_drawer.dart';
import 'payments_bills_screen.dart';
import 'profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Initial notifications list based on mockup
  final List<Map<String, dynamic>> _notifications = [
    {
      "id": "1",
      "title": "Rent Payment Due Soon",
      "description": "Your monthly rent for Room 402 is due in 3 days. Please ensure payment is completed by...",
      "timestamp": "2 hours ago",
      "isUnread": true,
      "group": "TODAY",
      "icon": Icons.credit_card_rounded,
      "iconColor": const Color(0xFF1D4ED8),
      "iconBg": const Color(0xFFEFF6FF),
      "hasAction": true,
      "actionText": "Pay Now",
    },
    {
      "id": "2",
      "title": "Special Dinner Menu Tonight",
      "description": "The dining hall is hosting a special international cuisine night tonight starting at 7:00 PM. Chec...",
      "timestamp": "5 hours ago",
      "isUnread": true,
      "group": "TODAY",
      "icon": Icons.restaurant_rounded,
      "iconColor": const Color(0xFF059669),
      "iconBg": const Color(0xFFECFDF5),
      "hasAction": false,
    },
    {
      "id": "3",
      "title": "Support Ticket Updated",
      "description": "Maintenance has responded to your ticket regarding the AC unit in Room 402. Status...",
      "timestamp": "Yesterday",
      "isUnread": false,
      "group": "YESTERDAY",
      "icon": Icons.confirmation_number_rounded,
      "iconColor": const Color(0xFFD97706),
      "iconBg": const Color(0xFFFFF7ED),
      "hasAction": false,
    },
    {
      "id": "4",
      "title": "Fire Drill Scheduled",
      "description": "A mandatory fire drill will be conducted for the Premium Wing tomorrow morning at 10:00 AM...",
      "timestamp": "Yesterday",
      "isUnread": false,
      "group": "YESTERDAY",
      "icon": Icons.campaign_rounded,
      "iconColor": const Color(0xFF4F46E5),
      "iconBg": const Color(0xFFEEF2FF),
      "hasAction": false,
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification["isUnread"] = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "All notifications marked as read",
          style: GoogleFonts.plusJakartaSans(),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n["id"] == id);
    if (index != -1 && _notifications[index]["isUnread"] == true) {
      setState(() {
        _notifications[index]["isUnread"] = false;
      });
    }
  }

  void _loadMoreNotifications() {
    setState(() {
      _notifications.addAll([
        {
          "id": (_notifications.length + 1).toString(),
          "title": "Shuttle Schedule Updated",
          "description": "New shuttle timings for weekdays have been uploaded. Check the updated schedules tab.",
          "timestamp": "2 days ago",
          "isUnread": false,
          "group": "PREVIOUS",
          "icon": Icons.directions_bus_rounded,
          "iconColor": const Color(0xFF0F172A),
          "iconBg": const Color(0xFFF1F5F9),
          "hasAction": false,
        },
        {
          "id": (_notifications.length + 2).toString(),
          "title": "Laundry Delivery",
          "description": "Your laundry batch #4982 is ready for pickup at the counter.",
          "timestamp": "3 days ago",
          "isUnread": false,
          "group": "PREVIOUS",
          "icon": Icons.local_laundry_service_rounded,
          "iconColor": const Color(0xFF06B6D4),
          "iconBg": const Color(0xFFECFEFF),
          "hasAction": false,
        }
      ]);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Loaded older notifications",
          style: GoogleFonts.plusJakartaSans(),
        ),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group notifications by their 'group' field
    final groups = <String, List<Map<String, dynamic>>>{};
    for (var n in _notifications) {
      groups.putIfAbsent(n["group"], () => []).add(n);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: UserDrawer(activeItem: "Notification"),
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
        title: Text(
          "Notifications",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded, color: Color(0xFF1D4ED8)),
            onPressed: () {},
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notifications header and Mark all as read button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Notifications",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  InkWell(
                    onTap: _markAllAsRead,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.done_all_rounded,
                            color: Color(0xFF1D4ED8),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Mark all as read",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Main Notifications Card Wrapper
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Dynamic generation of grouped lists
                    ...["TODAY", "YESTERDAY", "PREVIOUS"].where((g) => groups.containsKey(g)).map((groupName) {
                      final items = groups[groupName]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0, top: 20.0, bottom: 8.0),
                            child: Text(
                              groupName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF64748B),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (context, index) => const Divider(
                              color: Color(0xFFF1F5F9),
                              height: 1,
                              thickness: 1,
                            ),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final isUnread = item["isUnread"] == true;

                              return InkWell(
                                onTap: () => _markAsRead(item["id"]),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: isUnread
                                        ? const Border(
                                            left: BorderSide(
                                              color: Color(0xFF1D4ED8),
                                              width: 3.5,
                                            ),
                                          )
                                        : null,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Icon
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: item["iconBg"] as Color,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          item["icon"] as IconData,
                                          color: item["iconColor"] as Color,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      // Content details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          item["title"] as String,
                                                          style: GoogleFonts.plusJakartaSans(
                                                            fontSize: 14.5,
                                                            fontWeight: FontWeight.w700,
                                                            color: const Color(0xFF0F172A),
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (isUnread) ...[
                                                        const SizedBox(width: 6),
                                                        Container(
                                                          width: 6,
                                                          height: 6,
                                                          decoration: const BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            color: Color(0xFF1D4ED8),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  item["timestamp"] as String,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              item["description"] as String,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF475569),
                                                height: 1.4,
                                              ),
                                            ),
                                            if (item["hasAction"] == true) ...[
                                              const SizedBox(height: 12),
                                              ElevatedButton(
                                                onPressed: () {
                                                  _markAsRead(item["id"]);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => const PaymentsBillsScreen(),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF1D4ED8),
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                                  minimumSize: Size.zero,
                                                ),
                                                child: Text(
                                                  item["actionText"] as String,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Load More Button
              Center(
                child: OutlinedButton(
                  onPressed: _loadMoreNotifications,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1D4ED8),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    "Load More Notifications",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
