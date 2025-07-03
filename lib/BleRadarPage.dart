import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleRadarPage extends StatefulWidget {
  const BleRadarPage({super.key});

  @override
  State<BleRadarPage> createState() => _BleRadarPageState();
}

class _BleRadarPageState extends State<BleRadarPage> {
  final Map<String, _RadarDevice> devices = {};
  StreamSubscription? _scanSub;

  @override
  void initState() {
    super.initState();
    _checkPermissions().then((_) => _startScan());
  }

  Future<void> _checkPermissions() async {
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
  }

  void _startScan() {
    devices.clear();
    FlutterBluePlus.startScan();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        for (var result in results) {
          final id = result.device.remoteId.str;
          final distance = _estimateDistance(result.rssi);
          devices[id] = _RadarDevice(
            id: id,
            name: result.device.platformName.isNotEmpty
                ? result.device.platformName
                : result.advertisementData.advName.isNotEmpty
                    ? result.advertisementData.advName
                    : "(Unnamed)",
            rssi: result.rssi,
            distance: distance,
            angle: devices[id]?.angle ?? Random().nextDouble() * 2 * pi,
          );
        }
      });
    });

    Future.delayed(const Duration(seconds: 10), _stopScan);
  }

  void _stopScan() {
    FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _scanSub = null;
  }

  double _estimateDistance(int rssi) {
    const txPower = -59; // typical txPower at 1m
    if (rssi == 0) return -1;
    return pow(10, (txPower - rssi) / (10 * 2)).toDouble().clamp(0.5, 10.0);
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BLE Radar")),
      body: Center(
        child: LayoutBuilder(builder: (context, constraints) {
          final centerX = constraints.maxWidth / 2;
          final centerY = constraints.maxHeight / 2;
          final radius = min(centerX, centerY) - 40;

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RadarPainter(radius: radius),
                ),
              ),
              for (var device in devices.values)
                Positioned(
                  left: centerX +
                      cos(device.angle) *
                          (device.distance / 10.0) *
                          radius -
                      10,
                  top: centerY +
                      sin(device.angle) *
                          (device.distance / 10.0) *
                          radius -
                      10,
child: Column(
  children: [
    Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: _colorFromDistance(device.distance),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha((0.4 * 255).toInt()), 
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
              child: const Icon(Icons.bluetooth, size: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    device.name,
                    style: const TextStyle(fontSize: 9, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
                ),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startScan,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

Color _colorFromDistance(double d) {
  if (d < 2) return Colors.greenAccent;
  if (d < 5) return Colors.amber;
  return Colors.redAccent;
}


class _RadarDevice {
  final String id;
  final String name;
  final int rssi;
  final double distance;
  final double angle;

  _RadarDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.distance,
    required this.angle,
  });
}



class _RadarPainter extends CustomPainter {
  final double radius;

  _RadarPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, (radius / 3) * i, paint);
    }

    canvas.drawCircle(center, 4, Paint()..color = Colors.red); // Phone center
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
