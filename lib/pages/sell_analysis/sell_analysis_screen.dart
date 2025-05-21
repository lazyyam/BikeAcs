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
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = true;
  Map<String, int> _orderStatusCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchSalesData();
    _fetchTopDealsForMonth(_selectedMonth.year, _selectedMonth.month);
    _fetchOrderStatusCounts();
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
    final topDeals = await _sellAnalysisService.getTopDealsForMonth(year, month);
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
        title: const Text("Sell Analysis",
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
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKPISection() {
    final totalRevenue = _salesData['totalRevenue'] ?? 0.0;
    final totalOrders = _salesData['totalOrders'] ?? 0;

    return Column(
      children: [
        _buildKpiCard("Total Revenue", currencyFormatter.format(totalRevenue),
            Colors.orange),
        const SizedBox(height: 10),
        _buildKpiCard("Total Orders", totalOrders.toString(), Colors.teal),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
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
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Monthly Sales Trend",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...monthlyRevenue.entries.map((entry) {
            return ListTile(
              title: Text(entry.key),
              trailing: Text(currencyFormatter.format(entry.value)),
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
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Top Current Deals ($monthName)",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.calendar_today, color: Colors.grey),
                onPressed: _showMonthPicker,
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                      subtitle: Text(currencyFormatter.format(deal["price"])),
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

  Widget _buildPipelineCoverage() {
    final double closedDeals = 12000.0;
    final double forecastDeals = 18000.0;
    final double coverage =
        (forecastDeals == 0) ? 0 : (closedDeals / forecastDeals * 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Pipeline Coverage",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Coverage: ${coverage.toStringAsFixed(1)}%",
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: coverage / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }
}
