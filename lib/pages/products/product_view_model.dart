import 'dart:io';

import 'package:BikeAcs/pages/products/product_model.dart';
import 'package:BikeAcs/services/product_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ProductViewModel {
  final ProductDatabase _productDB = ProductDatabase();

  // Product Detail Functions
  Future<String> uploadImageToStorage(File imageFile) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.jpg';
      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child(fileName);

      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot taskSnapshot = await uploadTask;

      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String> upload3DModelToStorage(File modelFile) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.glb';
      final Reference ref =
          FirebaseStorage.instance.ref().child('ar_models').child(fileName);

      final UploadTask uploadTask = ref.putFile(modelFile);
      final TaskSnapshot taskSnapshot = await uploadTask;

      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload 3D model: $e');
    }
  }

  Future<void> delete3DModel(String arModelUrl) async {
    try {
      await FirebaseStorage.instance.refFromURL(arModelUrl).delete();
    } catch (e) {
      throw Exception('Failed to delete 3D model: $e');
    }
  }

  Future<void> saveProduct(Product? product, Product updatedProduct) async {
    try {
      if (product == null) {
        await _productDB.addProduct(updatedProduct);
      } else {
        await _productDB
            .setProduct(updatedProduct); // Ensure setProduct is used
      }
    } catch (e) {
      throw Exception('Failed to save product: $e');
    }
  }

  Future<void> deleteProduct(
      String productId, List<String> imageUrls, String? arModelUrl) async {
    try {
      for (String imageUrl in imageUrls) {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      }
      if (arModelUrl != null && arModelUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(arModelUrl).delete();
      }
      await _productDB.deleteProduct(productId);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<List<File>> pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();
    return images?.map((img) => File(img.path)).toList() ?? [];
  }

  Future<File?> pick3DModel() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      if (filePath.endsWith('.glb')) {
        return File(filePath);
      } else {
        throw Exception("Please select a .glb file");
      }
    }
    return null;
  }

  Future<Product?> refreshProductDetail(String productId) async {
    return await _productDB.getProduct(productId);
  }

  // Product Listing Functions
  Stream<List<Product>> getProductsStream(
      String category, bool isSearch, String searchQuery) {
    if (searchQuery.isNotEmpty) {
      return _productDB.searchProductsByName(searchQuery);
    } else if (!isSearch) {
      return _productDB.getProductsByCategory(category);
    } else {
      return _productDB.getProducts();
    }
  }
}
