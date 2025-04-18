import 'package:BikeAcs/services/order_tracking_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderStatusScreen extends StatefulWidget {
  final String trackingNumber;
  final String courierCode;

  const OrderStatusScreen({
    super.key,
    required this.trackingNumber,
    required this.courierCode,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  List<dynamic> checkpoints = [];
  String tag = '';
  String subtagMessage = '';
  String? deliveredAt;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTracking();
  }

  Future<void> loadTracking() async {
    try {
      final orderTrackingService = OrderTrackingService();
      final tracking = await orderTrackingService.fetchTrackingStatus(
        widget.trackingNumber,
        widget.courierCode,
      );

      setState(() {
        checkpoints = tracking['checkpoints']?.reversed?.toList() ?? [];
        tag = tracking['tag'] ?? 'Unknown';
        subtagMessage = tracking['subtag_message'] ?? '';
        deliveredAt = tracking['shipment_delivery_date'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching tracking status: $e");
    }
  }

  String formatTime(String? time) {
    if (time == null || time.isEmpty) return 'Unknown time';
    final parsed = DateTime.tryParse(time)?.toLocal();
    if (parsed == null) return 'Invalid date';
    return DateFormat('MMM dd, yyyy – hh:mm a').format(parsed);
  }

  Color getStatusColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'intransit':
        return Colors.orange;
      case 'pending':
        return Colors.grey;
      case 'exception':
      case 'failedattempt':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  IconData getStatusIcon(String tag) {
    switch (tag.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'intransit':
        return Icons.local_shipping_outlined;
      case 'pending':
        return Icons.hourglass_bottom;
      case 'exception':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text("Order Tracking",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : checkpoints.isEmpty && tag.toLowerCase() == 'pending'
              ? _buildEmptyState()
              : _buildStatusCard(),
    );
  }

  Widget _buildStatusCard() {
    return Column(
      children: [
        _buildStatusSummary(),
        const SizedBox(height: 4),
        const Divider(thickness: 1),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.builder(
            itemCount: checkpoints.length,
            itemBuilder: (context, index) {
              final item = checkpoints[index];
              final isLatest = index == 0;

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isLatest ? Colors.white : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      if (isLatest)
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: ListTile(
                    leading: Icon(
                      getStatusIcon(item['tag'] ?? ''),
                      color: getStatusColor(item['tag'] ?? ''),
                      size: 28,
                    ),
                    title: Text(
                      item['message'] ?? 'No message',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      formatTime(item['checkpoint_time']),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            getStatusColor(item['tag'] ?? '').withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item['tag']?.toUpperCase() ?? '',
                        style: TextStyle(
                          color: getStatusColor(item['tag'] ?? ''),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: getStatusColor(tag).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            getStatusIcon(tag),
            color: getStatusColor(tag),
            size: 40,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtagMessage.isNotEmpty ? subtagMessage : 'Status: $tag',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: getStatusColor(tag),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  deliveredAt != null
                      ? "Delivered on ${formatTime(deliveredAt)}"
                      : "Tracking #: ${widget.trackingNumber}",
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "Tracking not available yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Text(
              "We'll update this page once your courier picks up the item.",
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: getStatusColor(tag).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Status: $tag",
                style: TextStyle(
                  color: getStatusColor(tag),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
