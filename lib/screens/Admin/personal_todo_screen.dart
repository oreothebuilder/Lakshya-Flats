import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/personal_todo_model.dart';
import '../../models/user_role_model.dart';
import '../../services/firestore_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../widgets/admin_drawer.dart';
import '../../widgets/app_toast.dart';

class PersonalTodoScreen extends StatefulWidget {
  final AppUser? currentUser;

  const PersonalTodoScreen({
    super.key,
    this.currentUser,
  });

  @override
  State<PersonalTodoScreen> createState() => _PersonalTodoScreenState();
}

class _PersonalTodoScreenState extends State<PersonalTodoScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _taskController = TextEditingController();
  final FocusNode _taskFocusNode = FocusNode();

  String _filter = 'All'; // 'All', 'Pending', 'Completed'
  DateTime? _selectedDueDate;
  bool _isAdding = false;

  String get _adminUid {
    final uid = widget.currentUser?.uid ?? FirebaseAuthService().currentUser?.uid;
    return (uid != null && uid.isNotEmpty) ? uid : 'default_admin';
  }

  @override
  void dispose() {
    _taskController.dispose();
    _taskFocusNode.dispose();
    super.dispose();
  }

  void _showSnackbar(String msg, {bool isSuccess = true}) {
    AppToast.show(context, msg, isSuccess: isSuccess);
  }

  Future<void> _handleAddTask() async {
    final text = _taskController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAdding = true);
    try {
      await _firestoreService.addPersonalTodo(
        _adminUid,
        text,
        dueDate: _selectedDueDate,
      );
      _taskController.clear();
      setState(() {
        _selectedDueDate = null;
      });
      _taskFocusNode.requestFocus();
    } catch (e) {
      _showSnackbar("Failed to add task: $e", isSuccess: false);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D52CE),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  String _formatDueDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${d.day} ${months[d.month - 1]}";
  }

  void _confirmClearCompleted() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Clear Completed Tasks?",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          "This will remove all completed items from your personal list.",
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _firestoreService.clearCompletedPersonalTodos(_adminUid);
                _showSnackbar("Completed tasks cleared");
              } catch (e) {
                _showSnackbar("Error clearing tasks: $e", isSuccess: false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Clear", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      drawer: AdminDrawer(activeItem: "Personal To-Do", currentUser: widget.currentUser),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 24),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Personal To-Do",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              "Private tasks & reminders for admin",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<PersonalTodoModel>>(
        stream: _firestoreService.getPersonalTodosStream(_adminUid),
        builder: (context, snapshot) {
          final allTodos = snapshot.data ?? <PersonalTodoModel>[];
          final pendingCount = allTodos.where((t) => !t.isCompleted).length;
          final completedCount = allTodos.where((t) => t.isCompleted).length;

          final filtered = allTodos.where((t) {
            if (_filter == 'Pending') return !t.isCompleted;
            if (_filter == 'Completed') return t.isCompleted;
            return true;
          }).toList();

          return Column(
            children: [
              // 1. Quick Add Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(Icons.add_task_rounded, color: Color(0xFF0D52CE), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _taskController,
                              focusNode: _taskFocusNode,
                              onSubmitted: (_) => _handleAddTask(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: "Write a personal task or reminder...",
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 13.5,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          // Optional Due Date Picker Icon
                          IconButton(
                            icon: Icon(
                              _selectedDueDate != null
                                  ? Icons.event_available_rounded
                                  : Icons.calendar_today_rounded,
                              size: 18,
                              color: _selectedDueDate != null
                                  ? const Color(0xFF0D52CE)
                                  : const Color(0xFF64748B),
                            ),
                            tooltip: "Set Due Date",
                            onPressed: _pickDueDate,
                          ),
                          // Add Button
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: IconButton(
                              onPressed: _isAdding ? null : _handleAddTask,
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF0D52CE),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: _isAdding
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.arrow_upward_rounded, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Due Date Active Chip (if set)
                    if (_selectedDueDate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF0D52CE)),
                                const SizedBox(width: 6),
                                Text(
                                  "Due: ${_formatDueDate(_selectedDueDate!)}",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0D52CE),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => setState(() => _selectedDueDate = null),
                                  child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF0D52CE)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // 2. Filter Tabs & Summary Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip("All", allTodos.length),
                            const SizedBox(width: 8),
                            _buildFilterChip("Pending", pendingCount),
                            const SizedBox(width: 8),
                            _buildFilterChip("Completed", completedCount),
                          ],
                        ),
                      ),
                    ),
                    if (completedCount > 0) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _confirmClearCompleted,
                        icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Color(0xFFDC2626)),
                        label: Text(
                          "Clear Done",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 3. Task List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 36,
                                  color: Color(0xFF0D52CE),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _filter == 'Completed'
                                    ? "No completed tasks yet"
                                    : _filter == 'Pending'
                                        ? "All caught up! No pending tasks."
                                        : "Your personal to-do list is empty",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Quickly add thoughts or reminders using the bar above.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final todo = filtered[idx];
                          return Dismissible(
                            key: Key(todo.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                            ),
                            onDismissed: (_) {
                              _firestoreService.deletePersonalTodo(_adminUid, todo.id);
                              _showSnackbar("Task removed");
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: todo.isCompleted
                                      ? const Color(0xFFE2E8F0)
                                      : const Color(0xFFCBD5E1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.015),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Checkbox
                                  InkWell(
                                    onTap: () {
                                      _firestoreService.togglePersonalTodo(
                                        _adminUid,
                                        todo.id,
                                        !todo.isCompleted,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: todo.isCompleted
                                            ? const Color(0xFF16A34A)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color: todo.isCompleted
                                              ? const Color(0xFF16A34A)
                                              : const Color(0xFF94A3B8),
                                          width: 1.8,
                                        ),
                                      ),
                                      child: todo.isCompleted
                                          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Title & Due Date
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          todo.title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            decoration: todo.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: todo.isCompleted
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        if (todo.dueDate != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule_rounded,
                                                size: 13,
                                                color: todo.isOverdue
                                                    ? const Color(0xFFDC2626)
                                                    : todo.isDueToday
                                                        ? const Color(0xFFD97706)
                                                        : const Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                todo.isDueToday
                                                    ? "Due Today"
                                                    : todo.isOverdue
                                                        ? "Overdue (${_formatDueDate(todo.dueDate!)})"
                                                        : "Due ${_formatDueDate(todo.dueDate!)}",
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: todo.isOverdue
                                                      ? const Color(0xFFDC2626)
                                                      : todo.isDueToday
                                                          ? const Color(0xFFD97706)
                                                          : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Delete button
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                                    tooltip: "Delete Task",
                                    onPressed: () {
                                      _firestoreService.deletePersonalTodo(_adminUid, todo.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _filter == label;
    return ChoiceChip(
      label: Text(
        "$label ($count)",
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF0D52CE),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? const Color(0xFF0D52CE) : const Color(0xFFE2E8F0)),
      onSelected: (_) => setState(() => _filter = label),
    );
  }
}
