import 'package:cloud_firestore/cloud_firestore.dart';

class HomeCategoryDatabase {
  final CollectionReference _categoryCollection =
      FirebaseFirestore.instance.collection('categories');

  Future<List<Map<String, String>>> fetchCategories() async {
    try {
      final snapshot = await _categoryCollection.get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name'] as String})
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  Future<void> addCategory(String name) async {
    try {
      await _categoryCollection.add({'name': name});
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  Future<void> updateCategory(String id, String newName) async {
    try {
      await _categoryCollection.doc(id).update({'name': newName});
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _categoryCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }
}
