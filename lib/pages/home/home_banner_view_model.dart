import 'dart:io';

import '../../services/home_banner_database.dart';
import '../home/home_banner_model.dart';

class HomeBannerViewModel {
  final HomeBannerDatabase _bannerDatabase = HomeBannerDatabase();

  Future<List<HomeBannerModel>> fetchBanners() async {
    final banners = await _bannerDatabase.fetchBanners();
    return banners
        .map((data) => HomeBannerModel.fromMap(data['id'], data))
        .toList();
  }

  Future<void> addBanner(File imageFile) async {
    final imageUrl = await _bannerDatabase.uploadBannerImage(imageFile);
    await _bannerDatabase.addBanner(imageUrl);
  }

  Future<void> updateBanner(String id, File imageFile) async {
    final newImageUrl = await _bannerDatabase.uploadBannerImage(imageFile);
    await _bannerDatabase.updateBanner(id, newImageUrl);
  }

  Future<void> deleteBanner(String id) async {
    await _bannerDatabase.deleteBanner(id);
  }
}
