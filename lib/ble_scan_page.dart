import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:markus/BleDeviceDetailPage.dart';
import 'package:permission_handler/permission_handler.dart';

class BleMapperPage extends StatefulWidget {
  const BleMapperPage({super.key});

  @override
  _BleMapperPageState createState() => _BleMapperPageState();
}

class _BleMapperPageState extends State<BleMapperPage> {
  final List<ScanResult> _scanResults = [];
  final Map<DeviceIdentifier, int> _rssiMap = {};
  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions().then((_) => _startScan());
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
  _scanResults.clear();
  _stopScan(); 

  FlutterBluePlus.startScan();

  _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
    setState(() {
      for (var result in results) {
        _rssiMap[result.device.remoteId] = result.rssi;
        final existingIndex = _scanResults.indexWhere((r) => r.device.remoteId == result.device.remoteId);
        if (existingIndex == -1) {
          _scanResults.add(result);
        } else {
          _scanResults[existingIndex] = result;
        }
      }
    });
  });

  // Stop scan after 10 seconds
  Future.delayed(Duration(seconds: 10), _stopScan);
}

  void _stopScan() {
  FlutterBluePlus.stopScan();
  _scanSubscription?.cancel();
  _scanSubscription = null;
}

  double _estimateDistance(int rssi) {
    const txPower = -59; 
    if (rssi == 0) return -1.0;
    double _ = rssi / txPower;
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
      appBar: AppBar(title: Text('BLE Spatial Mapper')),
      body: ListView.builder(
        itemCount: _scanResults.length,
        itemBuilder: (context, index) {
          final result = _scanResults[index];
          return ListTile(
            title: Text(result.device.platformName.isNotEmpty
                ? result.device.platformName
                : result.advertisementData.advName.isNotEmpty
                    ? result.advertisementData.advName
                    : "(Unnamed Device)"),
            subtitle: Text("RSSI: ${result.rssi} → ~${_estimateDistance(result.rssi).toStringAsFixed(2)} m"),
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
        onPressed: _startScan,
        child: Icon(Icons.refresh),
      ),
    );
  }
}