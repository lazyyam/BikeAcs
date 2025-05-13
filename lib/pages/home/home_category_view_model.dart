import '../../services/home_category_database.dart';
import '../home/home_category_model.dart';

class HomeCategoryViewModel {
  final HomeCategoryDatabase _categoryDatabase = HomeCategoryDatabase();

  Future<List<HomeCategoryModel>> fetchCategories() async {
    final categoryData = await _categoryDatabase.fetchCategories();
    return categoryData
        .map((data) => HomeCategoryModel(id: data['id']!, name: data['name']!))
        .toList();
  }

  Future<void> addCategory(String name) async {
    await _categoryDatabase.addCategory(name);
  }

  Future<void> deleteCategory(String id) async {
    await _categoryDatabase.deleteCategory(id);
  }

  Future<void> updateCategory(String id, String newName) async {
    await _categoryDatabase.updateCategory(id, newName);
  }
}
