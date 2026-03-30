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
  PixelHandle? _pixelHandle;
  PixelStats? _currentStats;
  bool _isInitialized = false;
  int _refreshTimeSeconds = 5;
  final int _pixelSize = 40;
  final int _visibilityThreshold = 1;

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
      setState(() => _isInitialized = initialized);
    } catch (e) {
      _addEvent('Initialization failed: $e');
    }
  }

  void _listenToEvents() {
    VeonPixelTracker.events.listen((event) {
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
    if (_pixelHandle != null) {
      try {
        final stats = await _pixelHandle?.getStats();
        if (stats != null) {
          setState(() => _currentStats = stats);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error getting stats: $e');
        }
      }
    }
  }

  void _addEvent(String event) {
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
                                    onPlatformViewCreated: (handle) {
                                      setState(() {
                                        _pixelHandle = handle;
                                      });

                                      handle.setVisibilityCheckInterval(4);
                                      _addEvent('📱 Pixel handle received');
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
                  Text(
                    'Size: ${_pixelSize}px × ${_pixelSize}px',
                    style: const TextStyle(fontSize: 14),
                  ),
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
                  onPressed: _pixelHandle == null
                      ? null
                      : () {
                          _pixelHandle?.start();
                          _addEvent('▶️ Pixel started');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: _pixelHandle == null
                      ? null
                      : () {
                          _pixelHandle?.stop();
                          _addEvent('⏸️ Pixel stopped');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Stop'),
                ),
                ElevatedButton(
                  onPressed: _pixelHandle == null
                      ? null
                      : () {
                          _pixelHandle?.destroy();
                          setState(() => _pixelHandle = null);
                          _addEvent('🗑️ Pixel destroyed');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
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
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: _pixelHandle == null || _refreshTimeSeconds <= 0
                      ? null
                      : () {
                          setState(() => _refreshTimeSeconds--);
                          _pixelHandle?.updateRefreshTime(_refreshTimeSeconds);
                          _addEvent('⏱️ Refresh time: ${_refreshTimeSeconds}s');
                        },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_refreshTimeSeconds}s',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: _pixelHandle == null
                      ? null
                      : () {
                          setState(() => _refreshTimeSeconds++);
                          _pixelHandle?.updateRefreshTime(_refreshTimeSeconds);
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_currentStats != null) ...[
              Row(
                children: [
                  _buildStatItem(
                    'Appearances',
                    '${_currentStats?.totalAppearances ?? 0}',
                    Colors.blue,
                  ),
                  _buildStatItem(
                    'Visible',
                    _currentStats?.isCurrentlyVisible == true ? 'Yes' : 'No',
                    _currentStats?.isCurrentlyVisible == true
                        ? Colors.green
                        : Colors.red,
                  ),
                  _buildStatItem(
                    'Refresh',
                    _currentStats?.refreshEnabled == true ? 'On' : 'Off',
                    _currentStats?.refreshEnabled == true
                        ? Colors.green
                        : Colors.grey,
                  ),
                ],
              ),
              if (_currentStats?.nextRefreshInMs != null &&
                  _currentStats!.nextRefreshInMs > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Next refresh: ${_currentStats?.nextRefreshInSeconds ?? 0}s',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
            ] else
              const Text('No stats available'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Event Log',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: ListView.builder(
              reverse: true,
              itemCount: _events.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Text(
                    _events[index],
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pixelHandle?.destroy();
    VeonPixelTracker.shutdown();
    super.dispose();
  }

}
