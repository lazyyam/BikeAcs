class HomeBannerModel {
  final String id;
  final String imageUrl;

  HomeBannerModel({required this.id, required this.imageUrl});

  factory HomeBannerModel.fromMap(String id, Map<String, dynamic> data) {
    return HomeBannerModel(
      id: id,
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}
