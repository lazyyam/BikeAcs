import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class HomeBannerDatabase {
  final CollectionReference _bannerCollection =
      FirebaseFirestore.instance.collection('promo_banners');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<Map<String, dynamic>>> fetchBanners() async {
    try {
      final snapshot = await _bannerCollection.get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception('Error fetching banners: $e');
    }
  }

  Future<String> uploadBannerImage(File imageFile) async {
    try {
      final ref = _storage
          .ref()
          .child('promo_banners/${DateTime.now().toIso8601String()}');
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  Future<void> addBanner(String imageUrl) async {
    try {
      await _bannerCollection.add({'imageUrl': imageUrl});
    } catch (e) {
      throw Exception('Error adding banner: $e');
    }
  }

  Future<void> updateBanner(String id, String newImageUrl) async {
    try {
      // Fetch the current banner document
      final doc = await _bannerCollection.doc(id).get();
      if (doc.exists) {
        final oldImageUrl = doc['imageUrl'];

        // Delete the old image from Firebase Storage
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          await _storage.refFromURL(oldImageUrl).delete();
        }
      }

      // Update the banner with the new image URL
      await _bannerCollection.doc(id).update({'imageUrl': newImageUrl});
    } catch (e) {
      throw Exception('Error updating banner: $e');
    }
  }

  Future<void> deleteBanner(String id) async {
    try {
      // Fetch the current banner document
      final doc = await _bannerCollection.doc(id).get();
      if (doc.exists) {
        final imageUrl = doc['imageUrl'];

        // Delete the image from Firebase Storage
        if (imageUrl != null && imageUrl.isNotEmpty) {
          await _storage.refFromURL(imageUrl).delete();
        }
      }

      // Delete the banner document from Firestore
      await _bannerCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting banner: $e');
    }
  }
}
