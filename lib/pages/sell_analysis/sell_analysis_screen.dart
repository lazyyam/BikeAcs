// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors

import 'package:BikeAcs/services/sell_analysis_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';

class SellAnalysisScreen extends StatefulWidget {
  @override
  _SellAnalysisScreenState createState() => _SellAnalysisScreenState();
}

class _SellAnalysisScreenState extends State<SellAnalysisScreen> {
  final SellAnalysisService _sellAnalysisService = SellAnalysisService();
  final currencyFormatter =
      NumberFormat.currency(locale: 'en_MY', symbol: 'RM');
  Map<String, dynamic> _salesData = {};
  List<Map<String, dynamic>> _topDeals = [];
  List<Map<String, dynamic>> _topPositiveReviews = [];
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = true;
  Map<String, int> _orderStatusCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchSalesData();
    _fetchTopDealsForMonth(_selectedMonth.year, _selectedMonth.month);
    _fetchOrderStatusCounts();
    _fetchTopPositiveReviews(); // Fetch top positive reviews
  }

  Future<void> _fetchSalesData() async {
    setState(() => _isLoading = true);
    final salesData = await _sellAnalysisService.getSalesAnalysis();
    setState(() {
      _salesData = salesData;
      _isLoading = false;
    });
  }

  Future<void> _fetchTopDealsForMonth(int year, int month) async {
    final topDeals =
        await _sellAnalysisService.getTopDealsForMonth(year, month);
    setState(() {
      _topDeals = topDeals;
    });
  }

  Future<void> _fetchOrderStatusCounts() async {
    final statusCounts = await _sellAnalysisService.getOrderStatusCounts();
    setState(() {
      _orderStatusCounts = statusCounts;
    });
  }

  Future<void> _fetchTopPositiveReviews() async {
    final topPositiveReviews =
        await _sellAnalysisService.getTopPositiveReviewProducts();
    setState(() {
      _topPositiveReviews = topPositiveReviews;
    });
  }

  void _onMonthChanged(DateTime newMonth) {
    setState(() {
      _selectedMonth = newMonth;
    });
    _fetchTopDealsForMonth(newMonth.year, newMonth.month);
  }

  Future<void> _showMonthPicker() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: Colors.orange.shade100,
              headerForegroundColor: Colors.black,
            ),
          ),
          child: child!,
        );
      },
      initialDatePickerMode: DatePickerMode.year, // Start with year selection
    );

    if (selectedDate != null) {
      _onMonthChanged(DateTime(selectedDate.year, selectedDate.month));
    }
  }

  Widget _buildOrderStatusPieChart() {
    if (_orderStatusCounts.isEmpty) {
      return const Center(child: Text("No data available"));
    }

    final dataMap =
        _orderStatusCounts.map((key, value) => MapEntry(key, value.toDouble()));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Order Status Distribution",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          PieChart(
            dataMap: dataMap,
            chartType: ChartType.ring,
            chartRadius: MediaQuery.of(context).size.width / 2.5,
            legendOptions: const LegendOptions(
              showLegends: true,
              legendPosition: LegendPosition.bottom,
            ),
            chartValuesOptions: const ChartValuesOptions(
              showChartValuesInPercentage: true,
              showChartValuesOutside: false,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshPage() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchSalesData(),
      _fetchTopDealsForMonth(_selectedMonth.year, _selectedMonth.month),
      _fetchOrderStatusCounts(),
    ]);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Analysis",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshPage,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKPISection(),
                    const SizedBox(height: 20),
                    _buildSalesTrends(),
                    const SizedBox(height: 20),
                    _buildTopCurrentDeals(),
                    const SizedBox(height: 20),
                    _buildOrderStatusPieChart(),
                    const SizedBox(height: 20),
                    _buildTopPositiveReviews(), // Add the new section
                    const SizedBox(height: 26),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKPISection() {
    final totalRevenue = _salesData['totalRevenue'] ?? 0.0;
    final totalOrders = _salesData['totalOrders'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            "Total Revenue",
            currencyFormatter.format(totalRevenue),
            Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKpiCard(
            "Total Orders",
            totalOrders.toString(),
            Icons.shopping_bag_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFBA3B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFFFBA3B)),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTrends() {
    final monthlyRevenue = _salesData['monthlyRevenue'] ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFBA3B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Color(0xFFFFBA3B),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Monthly Sales Trend",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...monthlyRevenue.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    currencyFormatter.format(entry.value),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFBA3B),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopCurrentDeals() {
    final monthName = DateFormat.MMMM().format(_selectedMonth);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFBA3B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
                      color: Color(0xFFFFBA3B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Top Current Deals",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        monthName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today, size: 20),
                onPressed: _showMonthPicker,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _topDeals.isEmpty
              ? const Center(child: Text("No data available"))
              : Column(
                  children: _topDeals.map((deal) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: deal["image"] != null
                          ? Image.network(deal["image"], width: 40, height: 40)
                          : const Icon(Icons.image, size: 40),
                      title: Text(deal["name"] ?? "Unknown Product"),
                      // subtitle: Text(currencyFormatter.format(deal["price"])),
                      trailing: Text(
                        "${deal['orderCount']} orders",
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildTopPositiveReviews() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Top Positive Review Accessories",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _topPositiveReviews.isEmpty
              ? const Center(child: Text("No data available"))
              : Column(
                  children: _topPositiveReviews.map((product) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: product["image"] != null
                          ? Image.network(product["image"],
                              width: 40, height: 40)
                          : const Icon(Icons.image, size: 40),
                      title: Text(product["name"] ?? "Unknown Product"),
                      subtitle: Text(
                          "Avg. Rating: ${product['averageRating'].toStringAsFixed(1)} (${product['reviewCount']} reviews)"),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}
