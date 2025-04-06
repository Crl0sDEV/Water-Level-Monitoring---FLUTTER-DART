import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async'; // Import for Timer

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();
  Map<String, dynamic>? _latestData;
  List<BarChartGroupData> _chartData = [];
  List<Map<String, dynamic>> _chartRawData = [];
  bool _isLoading = true;
  Timer? _timer; // Timer for periodic fetching

  @override
  void initState() {
    super.initState();
    _initializeData();
    _startTimer(); // Start the timer when the screen initializes
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the screen is disposed
    super.dispose();
  }

  void _startTimer() {
    // Fetch data every 10 seconds (adjust the duration as needed)
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _fetchWaterData();
    });
  }

  Future<void> _initializeData() async {
    await _fetchWaterData();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchWaterData() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _logger.e("No internet connection.");
        setState(() {
          _latestData = null;
          _isLoading = false;
        });
        return;
      }

      final response = await _supabase
          .from('water_levels')
          .select('*')
          .order('last_updated', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _latestData = response;
        });
        await _fetchChartData();
      } else {
        _logger.e("Error fetching latest water data.");
      }
    } catch (e) {
      _logger.e("Error fetching water data: $e");
    }
  }

  Future<void> _fetchChartData() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _logger.e("No internet connection.");
        return;
      }

      final List<dynamic> chartResponse = await _supabase
          .from('water_levels')
          .select('*')
          .order('last_updated', ascending: false)
          .limit(5);

      if (chartResponse.isNotEmpty) {
        setState(() {
          _chartRawData = chartResponse.reversed.toList().map((item) => Map<String, dynamic>.from(item)).toList();
          _chartData = _chartRawData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (data['water_level'] as num?)?.toDouble() ?? 0.0,
                  color: const Color.fromARGB(255, 28, 112, 244),
                  width: 16,
                ),
              ],
            );
          }).toList();
        });
      } else {
        _logger.e("Error fetching chart data.");
      }
    } catch (e) {
      _logger.e("Error fetching chart data: $e");
    }
  }

  String _formatDateTime(String? timestamp) {
    if (timestamp == null) return 'Invalid date';
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      return DateFormat('MMM dd').format(dateTime);
    } catch (e) {
      _logger.e("Error formatting date: $e");
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 5,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${_latestData?['water_level'] ?? 'Loading...'}',
                                    style: TextStyle(
                                      fontSize: 60,
                                      fontWeight: FontWeight.bold,
                                      color: _getWaterLevelColor(
                                        (_latestData?['water_level'] as num?)?.toDouble(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatDateTime(_latestData?['last_updated']),
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            elevation: 5,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Color Code',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildColorCodeRow('Moderate', Colors.amber),
                                  const SizedBox(height: 8),
                                  _buildColorCodeRow('High', Colors.orange),
                                  const SizedBox(height: 8),
                                  _buildColorCodeRow('Critical', Colors.red),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_chartData.isNotEmpty)
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Water Level Chart',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 300,
                                child: BarChart(
                                  BarChartData(
                                    barGroups: _chartData,
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false), // Disable left titles
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (double value, _) {
                                            int index = value.toInt();
                                            if (index >= 0 && index < _chartRawData.length) {
                                              final date = _chartRawData[index]['last_updated'];
                                              return Text(
                                                _formatDateTime(date),
                                                style: const TextStyle(fontSize: 10),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ),
                                    ),
                                    gridData: FlGridData(show: true),
                                    borderData: FlBorderData(show: true),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Text('No chart data available.'),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildColorCodeRow(String label, Color color) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color,
          radius: 10,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Color _getWaterLevelColor(double? level) {
    if (level == null) return Colors.grey;
    if (level >= 3) {
      return Colors.red;
    } else if (level >= 2) {
      return Colors.orange;
    } else {
      return Colors.amber;
    }
  }
}