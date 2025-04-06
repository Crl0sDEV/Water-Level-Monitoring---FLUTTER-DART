import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  AlertsScreenState createState() => AlertsScreenState();
}

class AlertsScreenState extends State<AlertsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _highWaterLevels = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkConnectivityAndFetch();
  }

  Future<void> _checkConnectivityAndFetch() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _errorMessage = 'No internet connection. Please check your network.';
        _isLoading = false;
      });
      return;
    }
    await _fetchHighWaterLevels();
  }

  Future<void> _fetchHighWaterLevels() async {
    try {
      final response = await _supabase
          .from('water_levels')
          .select()
          .gte('water_level', 3)
          .order('last_updated', ascending: false);

      setState(() {
        _highWaterLevels =
            response.map((item) => Map<String, dynamic>.from(item)).toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('Exception: $e');
      setState(() {
        _errorMessage = 'Failed to load alerts: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String? timestamp) {
    if (timestamp == null) return 'Invalid date';
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          fontSize: 16, color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _highWaterLevels.isEmpty
                    ? const Center(
                        child: Text(
                          'No alerts at the moment.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _highWaterLevels.length,
                        itemBuilder: (context, index) {
                          final data = _highWaterLevels[index];
                          final isNewest = index == 0;

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withAlpha(51),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                          Colors.red.withAlpha(204),
                                      child: const Icon(Icons.warning,
                                          color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Critical Water Alert',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Level: ${data['water_level']} Meters',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Last updated: ${_formatDateTime(data['last_updated'])}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isNewest)
                                Positioned(
                                  top: 5,
                                  right: -28,
                                  child: Transform.rotate(
                                    angle: 0.7854,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade700,
                                      ),
                                      child: const Text(
                                        '      NEW      ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
      ),
    );
  }
}
