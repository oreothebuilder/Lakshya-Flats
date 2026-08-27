import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/user_drawer.dart';
import '../../services/auth_service.dart';
import '../../widgets/avatar_helper.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class PaymentsBillsScreen extends StatefulWidget {
  const PaymentsBillsScreen({super.key});

  @override
  State<PaymentsBillsScreen> createState() => _PaymentsBillsScreenState();
}

class _PaymentsBillsScreenState extends State<PaymentsBillsScreen> {
  String _activeTab = "To Be Paid"; // "To Be Paid" or "Paid Bills"

  final List<Map<String, dynamic>> _pendingBills = [
    {
      "icon": Icons.bolt_rounded,
      "title": "Electricity",
      "category": "Hostel Fees",
      "dueDate": "Due: 27 Aug 2026",
      "amount": "₹245",
      "status": "Upcoming",
    },
    {
      "icon": Icons.home_rounded,
      "title": "Month 2 Rent",
      "category": "Hostel Fees",
      "dueDate": "Due: 16 Sep 2026",
      "amount": "₹12,500",
      "status": "Upcoming",
    },
    {
      "icon": Icons.restaurant_rounded,
      "title": "Mess Bill - August",
      "category": "Hostel Fees",
      "dueDate": "Due: 05 Sep 2026",
      "amount": "₹4,500",
      "status": "Upcoming",
    },
    {
      "icon": Icons.wifi_rounded,
      "title": "WiFi Subscription",
      "category": "Hostel Fees",
      "dueDate": "Due: 28 Aug 2026",
      "amount": "₹500",
      "status": "Upcoming",
    },
    {
      "icon": Icons.home_rounded,
      "title": "Month 3 Rent",
      "category": "Hostel Fees",
      "dueDate": "Due: 16 Oct 2026",
      "amount": "₹12,500",
      "status": "Upcoming",
    },
  ];

  final List<Map<String, dynamic>> _paidBills = [
    {
      "icon": Icons.home_rounded,
      "title": "Month 1 Rent",
      "category": "Hostel Fees",
      "paidDate": "Paid on: 15 Aug 2026",
      "amount": "₹12,500",
      "status": "Paid",
    },
    {
      "icon": Icons.shield_rounded,
      "title": "Security Deposit",
      "category": "Hostel Fees",
      "paidDate": "Paid on: 10 Aug 2026",
      "amount": "₹15,000",
      "status": "Paid",
    },
    {
      "icon": Icons.bolt_rounded,
      "title": "Electricity - July",
      "category": "Hostel Fees",
      "paidDate": "Paid on: 25 Jul 2026",
      "amount": "₹220",
      "status": "Paid",
    },
    {
      "icon": Icons.restaurant_rounded,
      "title": "Mess Bill - July",
      "category": "Hostel Fees",
      "paidDate": "Paid on: 04 Aug 2026",
      "amount": "₹4,500",
      "status": "Paid",
    },
  ];



  void _showPaymentSnackbar(String billTitle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Processing payment for $billTitle...",
          style: GoogleFonts.plusJakartaSans(),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showReceiptSnackbar(String billTitle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Downloading receipt for $billTitle...",
          style: GoogleFonts.plusJakartaSans(),
        ),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = AuthService().currentUser;
    final initials = student?.initials.isNotEmpty == true ? student!.initials : "SU";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const UserDrawer(activeItem: "Payments & Bills"),
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
                Icons.apartment_rounded,
                color: Color(0xFF1A65D6),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Payments & Bills",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  student != null ? "${student.building} • Rm ${student.room}" : "Lakshya • Rm 304",
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
              child: StudentAvatar(
                radius: 18,
                profilePhotoUrl: student?.profilePhotoUrl,
                initials: initials,
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
              // Summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "HOSTEL FEES & PAYMENTS",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "10 Pending Dues",
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFFCA5A5),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "₹1,12,745",
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Total Outstanding Payable Amount",
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.white.withValues(alpha: 0.1), height: 1, thickness: 1),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Paid Dues
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    "₹62,500",
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF10B981),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Paid Dues",
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Divider
                        Container(
                          width: 1,
                          height: 32,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        const SizedBox(width: 12),
                        // Overdue Dues
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    "₹0",
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFFEF4444),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Overdue Dues",
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Divider
                        Container(
                          width: 1,
                          height: 32,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        const SizedBox(width: 12),
                        // Paid Receipts
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.receipt_long_rounded, color: Color(0xFF3B82F6), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    "4",
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF3B82F6),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Paid Receipts",
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Segmented Tab Bar Switcher
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                ),
                child: Row(
                  children: [
                    // To Be Paid Tab
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeTab = "To Be Paid";
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _activeTab == "To Be Paid" ? const Color(0xFF2563EB) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "To Be Paid",
                                style: GoogleFonts.plusJakartaSans(
                                  color: _activeTab == "To Be Paid" ? Colors.white : const Color(0xFF64748B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _activeTab == "To Be Paid" ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  "10",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: _activeTab == "To Be Paid" ? Colors.white : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Paid Bills Tab
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeTab = "Paid Bills";
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _activeTab == "Paid Bills" ? const Color(0xFF2563EB) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Paid Bills",
                                style: GoogleFonts.plusJakartaSans(
                                  color: _activeTab == "Paid Bills" ? Colors.white : const Color(0xFF64748B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _activeTab == "Paid Bills" ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFD1FAE5),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  "4",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: _activeTab == "Paid Bills" ? Colors.white : const Color(0xFF065F46),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bills List
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _activeTab == "To Be Paid" ? _buildPendingList() : _buildPaidList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingList() {
    return ListView.builder(
      key: const ValueKey("pending_list"),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pendingBills.length,
      itemBuilder: (context, index) {
        final bill = _pendingBills[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        bill["icon"] as IconData,
                        color: const Color(0xFF2563EB),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill["title"] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  bill["category"] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF2563EB),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                bill["dueDate"] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          bill["amount"] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            bill["status"] as String,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFD97706),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "To Be Paid",
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFEF4444),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showPaymentSnackbar(bill["title"] as String),
                      icon: const Icon(Icons.credit_card_rounded, size: 14, color: Colors.white),
                      label: Text(
                        "Pay / Submit Bill",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaidList() {
    return ListView.builder(
      key: const ValueKey("paid_list"),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _paidBills.length,
      itemBuilder: (context, index) {
        final bill = _paidBills[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        bill["icon"] as IconData,
                        color: const Color(0xFF2563EB),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill["title"] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  bill["category"] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF2563EB),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                bill["paidDate"] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          bill["amount"] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            bill["status"] as String,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF065F46),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "Paid Successfully",
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showReceiptSnackbar(bill["title"] as String),
                      icon: const Icon(Icons.download_rounded, size: 14, color: Color(0xFF64748B)),
                      label: Text(
                        "Receipt",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
