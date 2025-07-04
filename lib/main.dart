import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

import 'ble_scan_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Mapper',
      debugShowCheckedModeBanner: false,
      home: const StartupGate(),
    );
  }
}

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});
  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  @override
  void initState() {
    super.initState();
    _ensureLocationAvailable();
  }

  Future<void> _ensureLocationAvailable() async {
    // 1. Permission
    final perm = await Permission.locationWhenInUse.status;
    if (!perm.isGranted) {
      final req = await Permission.locationWhenInUse.request();
      if (!req.isGranted) return _closeApp();
    }

    // 2. GPS service
    if (!await Geolocator.isLocationServiceEnabled()) {
      await _promptEnableGps();
      if (!await Geolocator.isLocationServiceEnabled()) {
        return _closeApp();
      }
    }

    // All checks passed → go to BLE mapper
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BleMapperPage()),
      );
    }
  }

  Future<void> _promptEnableGps() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable GPS'),
        content: const Text('This app requires GPS. Please turn on location services.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    // Opens the device’s location settings
    await Geolocator.openLocationSettings();
  }

  void _closeApp() {
    // Optionally show a SnackBar first:
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GPS and permission required. Closing app.')),
    );
    Future.delayed(const Duration(seconds: 1), () {
      SystemNavigator.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show a loader while we’re checking
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
