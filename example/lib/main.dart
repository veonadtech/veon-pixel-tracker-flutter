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

  @override
  void initState() {
    super.initState();
    _initializeSdk();
    _listenToEvents();
  }

  Future<void> _initializeSdk() async {
    try {
      await VeonPixelTracker.initialize(
        baseUrl: "https://pixel-tracker.veonadtech.com/v1/pixel-event",
        debug: true,
      );

      final initialized = await VeonPixelTracker.isInitialized();
      setState(() => _isInitialized = initialized);

      if (initialized) {
        _createPixel();
      }
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

  Future<void> _createPixel() async {
    try {
      _pixelHandle = await VeonPixelTracker.createPixel(
        pixelId: 'demo_pixel_${DateTime.now().millisecondsSinceEpoch}',
        refreshTimeSeconds: _refreshTimeSeconds,
        pixelSize: _pixelSize,
        visibilityThreshold: 30,
        color: '#FF0000',
      );

      await _pixelHandle?.setVisibilityCheckInterval(3);
      await _pixelHandle?.start();

      _addEvent('Pixel created and started');
      _updateStats();
    } catch (e) {
      _addEvent('Failed to create pixel: $e');
    }
  }

  Future<void> _updateStats() async {
    if (_pixelHandle != null) {
      final stats = await _pixelHandle!.getStats();
      setState(() => _currentStats = stats);
    }
  }

  void _addEvent(String event) {
    setState(() {
      _events.insert(0, '${DateTime.now().toString().substring(11, 19)}: $event');
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
        body: Column(
          children: [
            if (!_isInitialized)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildStatusCard(),
                      _buildControls(),
                      _buildStatsCard(),
                      _buildEventsList(),
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
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pixel Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: _pixelSize.toDouble(),
              height: _pixelSize.toDouble(),
              color: Colors.red,
            ),
            const SizedBox(height: 8),
            Text(
              'Size: ${_pixelSize}px × ${_pixelSize}px',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _pixelHandle == null ? null : () {
                    _pixelHandle?.start();
                    _addEvent('Pixel started');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: _pixelHandle == null ? null : () {
                    _pixelHandle?.stop();
                    _addEvent('Pixel stopped');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Stop'),
                ),
                ElevatedButton(
                  onPressed: _pixelHandle == null ? null : () {
                    _pixelHandle?.destroy();
                    setState(() => _pixelHandle = null);
                    _addEvent('Pixel destroyed');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Destroy'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Refresh time: '),
                IconButton(
                  icon: const Icon(Icons.remove_circle),
                  onPressed: _pixelHandle == null || _refreshTimeSeconds <= 0
                      ? null
                      : () {
                    setState(() => _refreshTimeSeconds--);
                    _pixelHandle?.updateRefreshTime(_refreshTimeSeconds);
                    _addEvent('Refresh time updated to ${_refreshTimeSeconds}s');
                  },
                ),
                Text('${_refreshTimeSeconds}s'),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _pixelHandle == null ? null : () {
                    setState(() => _refreshTimeSeconds++);
                    _pixelHandle?.updateRefreshTime(_refreshTimeSeconds);
                    _addEvent('Refresh time updated to ${_refreshTimeSeconds}s');
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
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_currentStats != null) ...[
              Text('Total appearances: ${_currentStats!.totalAppearances}'),
              Text('Currently visible: ${_currentStats!.isCurrentlyVisible ? "Yes" : "No"}'),
              Text('Refresh enabled: ${_currentStats!.refreshEnabled ? "Yes" : "No"}'),
              if (_currentStats!.nextRefreshInMs > 0)
                Text('Next refresh: ${_currentStats!.nextRefreshInSeconds}s'),
            ] else
              const Text('No stats available'),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Events',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              reverse: true,
              itemCount: _events.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    _events[index],
                    style: const TextStyle(fontSize: 12),
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