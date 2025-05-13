// ignore_for_file: prefer_final_fields, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'review_view_model.dart';

class ReviewScreen extends StatefulWidget {
  final String productId;
  const ReviewScreen({super.key, required this.productId});

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late ReviewViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ReviewViewModel();
    _viewModel.fetchReviews(widget.productId, context);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _viewModel,
      child: Consumer<ReviewViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(title: const Text('Reviews')),
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.reviews.isEmpty
                    ? const Center(
                        child: Text(
                          'No Reviews Available',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: viewModel.reviews.length,
                        itemBuilder: (ctx, i) {
                          var review = viewModel.reviews[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    NetworkImage(review['avatar'] ?? ''),
                              ),
                              title: Text(review['name'] ?? 'Anonymous',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: List.generate(
                                      5,
                                      (index) => Icon(
                                        index < (review['rating'] ?? 0)
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  if (review['opinion'] != null &&
                                      review['opinion'].isNotEmpty)
                                    Text(
                                      review['opinion'],
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          );
        },
      ),
    );
  }
}
