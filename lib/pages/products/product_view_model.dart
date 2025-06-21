import 'dart:io';

import 'package:BikeAcs/pages/products/product_model.dart';
import 'package:BikeAcs/services/product_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ProductViewModel {
  final ProductDatabase _productDB = ProductDatabase();

  // Product Detail Functions
  Future<String> uploadImageToStorage(File imageFile) async {
    try {
      final String fileExtension =
          path.extension(imageFile.path); // e.g., .png, .jpg
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}$fileExtension';

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

  Future<void> update3DModelUrl(String productId, String? arModelUrl) async {
    await _productDB.update3DModelUrl(productId, arModelUrl);
  }

  Future<void> saveProduct(Product? product, Product updatedProduct,
      bool enableColor, bool enableSize) async {
    try {
      if (product == null) {
        await _productDB.addProduct(updatedProduct);
      } else {
        await _productDB.setProduct(updatedProduct, enableColor,
            enableSize); // Ensure setProduct is used
      }
    } catch (e) {
      throw Exception('Failed to save accessory: $e');
    }
  }

  Future<void> deleteProduct(
      String productId, List<String> imageUrls, String? arModelUrl) async {
    try {
      // for (String imageUrl in imageUrls) {
      //   await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      // }
      if (arModelUrl != null && arModelUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(arModelUrl).delete();
      }
      await _productDB.deleteProduct(productId);
    } catch (e) {
      throw Exception('Failed to delete accessory: $e');
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

  Future<Product?> getProductById(String productId) async {
    try {
      return await _productDB.getProduct(productId);
    } catch (e) {
      throw Exception('Failed to fetch accessory: $e');
    }
  }

  // Product Listing Functions
  Stream<List<Product>> getProductsStream(
      String category, bool isSearch, String searchQuery,
      {double? minPrice, double? maxPrice}) {
    return _productDB.getProductsStream(
      category: isSearch ? null : category,
      searchQuery: searchQuery.toLowerCase(), // Convert query to lowercase
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  Stream<List<Product>> getLowStockProducts() {
    return _productDB.getLowStockProducts();
  }

  Future<void> decreaseVariantStock(
      String productId, String? color, String? size, int quantity) async {
    try {
      final product = await _productDB.getProduct(productId);
      if (product == null) {
        throw Exception('Accessory not found');
      }

      final variantKey =
          (color != null && size != null) ? '$color-$size' : (color ?? size);

      if (variantKey != null && product.variantStock.containsKey(variantKey)) {
        final updatedVariantStock = Map<String, int>.from(product.variantStock);
        updatedVariantStock[variantKey] =
            (updatedVariantStock[variantKey]! - quantity)
                .clamp(0, double.infinity)
                .toInt();

        // Update variant stock in Firestore
        await _productDB.updateVariantStock(productId, updatedVariantStock);

        // Synchronize overall stock with the sum of variant stocks
        final totalStock =
            updatedVariantStock.values.fold(0, (sum, qty) => sum + qty);
        await _productDB.updateStock(productId, totalStock);
      } else {
        // Reduce overall stock if no variant key is provided
        await _productDB.decreaseStock(productId, quantity);
      }
    } catch (e) {
      throw Exception('Failed to decrease variant stock: $e');
    }
  }

  Future<void> notifyLowStock(String productId) async {
    try {
      final product = await _productDB.getProduct(productId);
      if (product != null && product.stock <= 10) {
        print("Notify admin: Product ${product.name} is low in stock.");
        // Add notification logic here (e.g., update Firestore or trigger a UI update)
      }
    } catch (e) {
      throw Exception('Failed to notify low stock: $e');
    }
  }
}
