import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:veon_pixel_tracker_flutter/veon_pixel_tracker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<String> _events = [];

  PixelController? _pixelController;
  PixelStats? _currentStats;

  bool _isInitialized = false;

  int _refreshTimeSeconds = 5;
  final int _pixelSize = 40;
  final int _visibilityThreshold = 1;

  StreamSubscription? _sdkSubscription;

  @override
  void initState() {
    super.initState();
    _initializeSdk();
    _listenToEvents();
  }

  Future<void> _initializeSdk() async {
    try {
      await VeonPixelTracker.initialize(
        baseUrl: "Enter your base URL here",
        debug: true,
      );

      final initialized = await VeonPixelTracker.isInitialized();

      if (mounted) {
        setState(() => _isInitialized = initialized);
      }
    } catch (e) {
      _addEvent('Initialization failed: $e');
    }
  }

  void _listenToEvents() {
    _sdkSubscription = VeonPixelTracker.events.listen((event) {
      final eventType = event['event'];
      final data = event['data'] != null
          ? Map<String, dynamic>.from(event['data'] as Map)
          : null;

      if (eventType == 'initialized') {
        final status = data?['status'];
        final message = data?['message'];
        _addEvent('SDK $status: $message');
      } else if (eventType == 'pixel_event') {
        final pixelId = data?['pixelId'];
        final type = data?['type'];
        final timestamp = data?['timestamp'];

        _addEvent('Pixel $pixelId: $type at $timestamp');

        if (type == 'appearance' || type == 'refresh') {
          _updateStats();
        }
      } else if (eventType == 'shutdown') {
        _addEvent('SDK shutdown');
      }
    });
  }

  Future<void> _updateStats() async {
    final controller = _pixelController;
    if (controller == null || !mounted) return;

    try {
      final stats = await controller.getStats();
      if (mounted) {
        setState(() => _currentStats = stats);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting stats: $e');
      }
    }
  }

  void _addEvent(String event) {
    if (!mounted) return;

    setState(() {
      _events.insert(
        0,
        '${DateTime.now().toString().substring(11, 19)}: $event',
      );
      if (_events.length > 20) _events.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PixelTracker Demo'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: !_isInitialized
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildStatusCard(),
                  _buildControls(),
                  _buildStatsCard(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildEventsList(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 2,
                            child: Stack(
                              children: [
                                Positioned(
                                  top: MediaQuery.of(context).size.height * 1,
                                  left:
                                      MediaQuery.of(context).size.width / 2 -
                                      _pixelSize / 2,
                                  child: PixelTrackerView(
                                    pixelId: 'demo_pixel_1',
                                    refreshTimeSeconds: _refreshTimeSeconds,
                                    pixelSize: _pixelSize,
                                    visibilityThreshold: _visibilityThreshold,
                                    color: '#FF0000',
                                    onPixelCreated: (controller) {
                                      if (!mounted) return;
                                      setState(() {
                                        _pixelController = controller;
                                      });
                                      controller.setVisibilityCheckInterval(4);
                                      controller.start();
                                      _addEvent('📱 Pixel controller received');
                                    },
                                    onEvent: (event) {
                                      if (event.isAppearance) {
                                        _addEvent('✅ Pixel VISIBLE');
                                        _updateStats();
                                      } else if (event.isDisappearance) {
                                        _addEvent('👻 Pixel HIDDEN');
                                        _updateStats();
                                      } else if (event.isRefresh) {
                                        _addEvent('🔄 Pixel REFRESH');
                                        _updateStats();
                                      } else if (event.isError) {
                                        _addEvent('❌ Error: ${event.error}');
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: _pixelSize.toDouble(),
              height: _pixelSize.toDouble(),
              color: Colors.red,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pixel Tracker',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text('Size: ${_pixelSize}px × ${_pixelSize}px'),
                  Text(
                    'Position: ↓ Scroll down to see',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    final controller = _pixelController;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'Controls',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: controller == null
                      ? null
                      : () {
                          controller.start();
                          _addEvent('▶️ Pixel started');
                        },
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: controller == null
                      ? null
                      : () {
                          controller.stop();
                          _addEvent('⏸️ Pixel stopped');
                        },
                  child: const Text('Stop'),
                ),
                ElevatedButton(
                  onPressed: controller == null
                      ? null
                      : () {
                          controller.destroy();
                          if (mounted) {
                            setState(() => _pixelController = null);
                          }
                          _addEvent('🗑️ Pixel destroyed');
                        },
                  child: const Text('Destroy'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Refresh time: '),
                IconButton(
                  icon: const Icon(Icons.remove_circle),
                  onPressed: controller == null || _refreshTimeSeconds <= 0
                      ? null
                      : () {
                          setState(() => _refreshTimeSeconds--);
                          controller.updateRefreshTime(_refreshTimeSeconds);
                          _addEvent('⏱️ Refresh time: ${_refreshTimeSeconds}s');
                        },
                ),
                Text('$_refreshTimeSeconds s'),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: controller == null
                      ? null
                      : () {
                          setState(() => _refreshTimeSeconds++);
                          controller.updateRefreshTime(_refreshTimeSeconds);
                          _addEvent('⏱️ Refresh time: ${_refreshTimeSeconds}s');
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = _currentStats;
    if (stats == null) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('No stats available'),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text('Appearances: ${stats.totalAppearances}'),
            Text('Visible: ${stats.isCurrentlyVisible ? "Yes" : "No"}'),
            Text('Refresh: ${stats.refreshEnabled ? "On" : "Off"}'),
            Text('Next refresh: ${stats.nextRefreshInSeconds}s'),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        reverse: true,
        itemCount: _events.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(_events[index], style: const TextStyle(fontSize: 11)),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _sdkSubscription?.cancel();
    _pixelController?.destroy();
    VeonPixelTracker.shutdown();
    super.dispose();
  }

}
