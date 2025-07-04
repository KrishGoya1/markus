import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:markus/BleDeviceDetailPage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_device_identifier.dart';
import 'discovered_device.dart';
import 'dart:convert';

class BleMapperPage extends StatefulWidget {
  const BleMapperPage({super.key});

  @override
  _BleMapperPageState createState() => _BleMapperPageState();
}

const _gpsServiceUuid = "12345678-1234-1234-1234-1234567890ab";

class _BleMapperPageState extends State<BleMapperPage> {
  final List<DiscoveredDevice> _devices = [];
  final List<ScanResult> _scanResults = [];
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
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  void _startScan() {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final now = DateTime.now();
      setState(() {
        _devices.clear();
        _scanResults.clear();
        _scanResults.addAll(results);
        for (final result in results) {
          final adv = result.advertisementData;
          double? lat, lon;
          final gpsRaw = adv.serviceData[Guid(_gpsServiceUuid)];
          if (gpsRaw != null) {
            try {
              final parts = utf8.decode(gpsRaw).split(',');
              lat = double.parse(parts[0]);
              lon = double.parse(parts[1]);
            } catch (_) {}
          }
          final dev = DiscoveredDevice(
            id: result.device.remoteId,
            name: BleDeviceIdentifier.getDeviceName(result),
            rssi: result.rssi,
            lastSeen: now,
            connectable: adv.connectable,
            manufacturerData: adv.manufacturerData,
            serviceData: adv.serviceData,
            latitude: lat,
            longitude: lon,
          );
          final idx = _devices.indexWhere((d) => d.id == dev.id);
          if (idx == -1) {
            _devices.add(dev);
          } else {
            _devices[idx] = dev;
          }
        }
        _devices.sort((a, b) => b.rssi.compareTo(a.rssi));
      });
    });

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
      _devices.removeWhere((device) => device.lastSeen.isBefore(cutoff));
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
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
        ],
      ),
      body: _devices.isEmpty
          ? Center(child: Text('No devices found'))
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final dev = _devices[index];
                final rssi = dev.rssi;

                // RSSI signal strength indicator
                IconData signalIcon;
                Color signalColor;

                if (rssi > -60) {
                  signalIcon = Icons.signal_cellular_4_bar;
                  signalColor = Colors.green;
                } else if (rssi > -70) {
                  signalIcon = Icons.signal_cellular_alt;
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
                  title: Text(dev.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "RSSI: ${dev.rssi} dBm • Last seen: ${DateTime.now().difference(dev.lastSeen).inSeconds}s ago",
                      ),
                      if (dev.latitude != null && dev.longitude != null)
                        Text(
                          "Coords: ${dev.latitude!.toStringAsFixed(5)}, ${dev.longitude!.toStringAsFixed(5)}",
                        ),
                    ],
                  ),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    final device = _scanResults.firstWhereOrNull(
                      (element) => element.device.remoteId == dev.id,
                    );

                    if (device != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BleDeviceDetailPage(
                            device: device,
                            result: device,
                            advertisementData: device.advertisementData,
                            manufacturerData:
                                device.advertisementData.manufacturerData,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Device disconnected - showing last known info',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
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
