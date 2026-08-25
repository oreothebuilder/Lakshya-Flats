import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/student_model.dart';

class StudentService extends ChangeNotifier {
  static final StudentService _instance = StudentService._internal();
  factory StudentService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StudentService._internal();

  // Uploads an image to Firebase Storage and returns its download URL.
  // If configuration or upload fails, falls back gracefully to returning local path.
  Future<String> uploadImage(String studentId, String filePath, String type) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return filePath;
      }
      final ref = FirebaseStorage.instance
          .ref()
          .child('students')
          .child(studentId)
          .child('$type.jpg');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print("Error uploading image to Firebase Storage: $e");
      }
      // Return the local file path as a fallback
      return filePath;
    }
  }

  // Stream of all students
  Stream<List<StudentDirectoryItem>> getStudentsStream() {
    return _firestore.collection('students').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return StudentDirectoryItem.fromJson(doc.data());
      }).toList();
    });
  }

  // Add a new student
  Future<void> addStudent(StudentDirectoryItem student) async {
    await _firestore.collection('students').doc(student.id).set(student.toJson());
  }

  // Update an existing student's details (notes, pendingAmount, status etc)
  Future<void> updateStudent(StudentDirectoryItem student) async {
    await _firestore.collection('students').doc(student.id).update(student.toJson());
  }

  // Delete student
  Future<void> deleteStudent(String studentId) async {
    await _firestore.collection('students').doc(studentId).delete();
  }

  // Stream of all onboarding drafts
  Stream<List<Map<String, dynamic>>> getDraftsStream() {
    return _firestore.collection('onboarding_drafts').orderBy('updatedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['draftId'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Save/Update onboarding draft
  Future<void> saveDraft(String draftId, Map<String, dynamic> draftData) async {
    await _firestore.collection('onboarding_drafts').doc(draftId).set(
      {
        ...draftData,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // Delete onboarding draft
  Future<void> deleteDraft(String draftId) async {
    await _firestore.collection('onboarding_drafts').doc(draftId).delete();
  }
}
