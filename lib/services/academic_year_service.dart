import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AcademicYearService {
  static final AcademicYearService instance = AcademicYearService._internal();
  AcademicYearService._internal();

  static const String defaultYear = "2026-2027";
  static const String _prefKey = "lakshya_selected_academic_year";
  static const String _configDoc = "academic_years";

  final ValueNotifier<String> selectedYearNotifier = ValueNotifier<String>(defaultYear);
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _initialized = false;

  String get selectedYear => selectedYearNotifier.value;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedYear = prefs.getString(_prefKey);
      if (savedYear != null && savedYear.trim().isNotEmpty) {
        selectedYearNotifier.value = savedYear.trim();
      } else {
        selectedYearNotifier.value = defaultYear;
      }

      // Ensure system_config/academic_years exists in Firestore
      final doc = await _db.collection('system_config').doc(_configDoc).get();
      if (!doc.exists) {
        await _db.collection('system_config').doc(_configDoc).set({
          'years': [defaultYear],
          'activeYear': defaultYear,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      _initialized = true;
    } catch (e) {
      debugPrint("AcademicYearService initialize error: $e");
    }
  }

  Future<void> setSelectedYear(String year) async {
    final clean = year.trim();
    if (clean.isEmpty) return;
    selectedYearNotifier.value = clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, clean);
    } catch (e) {
      debugPrint("Error saving selected academic year: $e");
    }
  }

  Stream<List<String>> getAcademicYearsStream() {
    return _db.collection('system_config').doc(_configDoc).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return [defaultYear];
      }
      final data = snap.data()!;
      final list = (data['years'] as List?)?.map((e) => e.toString().trim()).toList() ?? [defaultYear];
      if (!list.contains(defaultYear)) {
        list.insert(0, defaultYear);
      }
      list.sort((a, b) => a.compareTo(b));
      return list;
    });
  }

  Future<List<String>> getAcademicYears() async {
    try {
      final snap = await _db.collection('system_config').doc(_configDoc).get();
      if (snap.exists && snap.data() != null) {
        final list = (snap.data()!['years'] as List?)?.map((e) => e.toString().trim()).toList() ?? [defaultYear];
        if (!list.contains(defaultYear)) {
          list.insert(0, defaultYear);
        }
        list.sort((a, b) => a.compareTo(b));
        return list;
      }
    } catch (e) {
      debugPrint("getAcademicYears error: $e");
    }
    return [defaultYear];
  }

  Future<bool> addAcademicYear(String newYear) async {
    final clean = newYear.trim();
    if (clean.isEmpty) return false;

    // Validate format like "2027-2028"
    final regex = RegExp(r'^\d{4}-\d{4}$');
    if (!regex.hasMatch(clean)) {
      throw Exception("Academic Year format must be YYYY-YYYY (e.g., 2027-2028)");
    }

    try {
      await _db.collection('system_config').doc(_configDoc).set({
        'years': FieldValue.arrayUnion([clean]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await setSelectedYear(clean);
      return true;
    } catch (e) {
      debugPrint("addAcademicYear error: $e");
      rethrow;
    }
  }

  /// Proposes the next logical academic year based on current known years
  static String proposeNextAcademicYear(List<String> existingYears) {
    if (existingYears.isEmpty) return "2027-2028";
    final lastYear = existingYears.last;
    final parts = lastYear.split('-');
    if (parts.length == 2) {
      final endYear = int.tryParse(parts[1].trim());
      if (endYear != null) {
        return "$endYear-${endYear + 1}";
      }
    }
    return "2027-2028";
  }

  /// Calculates academic years spanned by lease dates, capped strictly at the current academic year.
  /// A student staying in for the current academic year (2026-2027) is associated with this year
  /// (and any years they have stayed before) only, never future uncreated years.
  static List<String> calculateAcademicYears(String? startDateStr, String? endDateStr) {
    final Set<String> years = {};

    DateTime? parseDate(String? s) {
      if (s == null || s.trim().isEmpty) return null;
      final clean = s.trim();
      // Try dd/MM/yyyy
      final parts = clean.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          return DateTime(y, m, d);
        }
      }
      return DateTime.tryParse(clean);
    }

    final start = parseDate(startDateStr);
    final end = parseDate(endDateStr);

    final currentYear = instance.selectedYear.trim().isNotEmpty
        ? instance.selectedYear.trim()
        : defaultYear;
    final currentStartYear = int.tryParse(currentYear.split('-').first.trim()) ?? 2026;

    if (start != null) {
      int startYear = start.year;
      if (start.month < 6) {
        startYear -= 1;
      }
      int endYear = (end ?? start.add(const Duration(days: 365))).year;
      if ((end != null && end.month >= 6) || end == null) {
        endYear += 1;
      }

      for (int y = startYear; y < endYear; y++) {
        // Only associate with current academic year and years stayed before
        if (y <= currentStartYear) {
          years.add("$y-${y + 1}");
        }
      }
    }

    if (years.isEmpty) {
      years.add(currentYear);
    }
    final sorted = years.toList()..sort();
    return sorted;
  }
}
