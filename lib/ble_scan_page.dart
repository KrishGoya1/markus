import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:markus/BleDeviceDetailPage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_device_identifier.dart';

class BleMapperPage extends StatefulWidget {
  const BleMapperPage({super.key});

  @override
  _BleMapperPageState createState() => _BleMapperPageState();
}

class _BleMapperPageState extends State<BleMapperPage> {
  final List<ScanResult> _scanResults = [];
  final Map<DeviceIdentifier, int> _rssiMap = {};
  final Map<DeviceIdentifier, DateTime> _lastSeenMap = {};
  StreamSubscription? _scanSubscription;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions().then((_) => _startScan());
    
    // Set up periodic cleanup of old devices
    Timer.periodic(const Duration(seconds: 30), (_) => _cleanupOldDevices());
  }

  Future<void> _checkPermissions() async {
    await [Permission.bluetooth, Permission.bluetoothScan, 
           Permission.bluetoothConnect, Permission.location].request();
  }

  void _startScan() {
    if (_isScanning) return;
    
    setState(() {
      _isScanning = true;
    });
    
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        for (var result in results) {
          _rssiMap[result.device.remoteId] = result.rssi;
          _lastSeenMap[result.device.remoteId] = DateTime.now();
          
          final existingIndex = _scanResults.indexWhere(
              (r) => r.device.remoteId == result.device.remoteId);
          
          if (existingIndex == -1) {
            _scanResults.add(result);
          } else {
            _scanResults[existingIndex] = result;
          }
        }
        
        // Sort by signal strength
        _scanResults.sort((a, b) => b.rssi.compareTo(a.rssi));
      });
    });

    // Stop scan after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      _stopScan();
    });
  }

  void _stopScan() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = null;
    
    setState(() {
      _isScanning = false;
    });
  }

  void _cleanupOldDevices() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(minutes: 2));
    
    setState(() {
      _scanResults.removeWhere((result) {
        final lastSeen = _lastSeenMap[result.device.remoteId];
        return lastSeen != null && lastSeen.isBefore(cutoff);
      });
    });
  }

  double _estimateDistance(int rssi) {
    const txPower = -59; 
    if (rssi == 0) return -1.0;
    return pow(10, (txPower - rssi) / (10 * 2)).toDouble();
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BLE Spatial Mapper'),
        actions: [
          if (_isScanning)
            Container(
              margin: const EdgeInsets.all(16),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
        ],
      ),
      body: _scanResults.isEmpty
          ? Center(child: Text('No devices found'))
          : ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                final result = _scanResults[index];
                final deviceName = BleDeviceIdentifier.getDeviceName(result);
                final rssi = result.rssi;
                final distance = _estimateDistance(rssi);
                final lastSeen = _lastSeenMap[result.device.remoteId] ?? DateTime.now();
                final timeSinceLastSeen = DateTime.now().difference(lastSeen);
                
                // RSSI signal strength indicator
                IconData signalIcon;
                Color signalColor;
                
                if (rssi > -60) {
                  signalIcon = Icons.signal_cellular_4_bar;
                  signalColor = Colors.green;
                } else if (rssi > -70) {
                  signalIcon = Icons.signal_cellular_alt ;
                  signalColor = Colors.lightGreen;
                } else if (rssi > -80) {
                  signalIcon = Icons.signal_cellular_alt_2_bar;
                  signalColor = Colors.orange;
                } else {
                  signalIcon = Icons.signal_cellular_alt_1_bar_sharp;
                  signalColor = Colors.red;
                }
                
                return ListTile(
                  leading: Icon(signalIcon, color: signalColor),
                  title: Text(deviceName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("RSSI: $rssi dBm • ~${distance.toStringAsFixed(1)} m"),
                      Text(
                        "Last seen: ${timeSinceLastSeen.inSeconds}s ago",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BleDeviceDetailPage(result: result),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? _stopScan : _startScan,
        child: Icon(_isScanning ? Icons.stop : Icons.refresh),
      ),
    );
  }
}