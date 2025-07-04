import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DiscoveredDevice {
  final DeviceIdentifier id;
  final String name;
  final int rssi;
  final DateTime lastSeen;
  final bool connectable;
  final Map<int, List<int>> manufacturerData;
  final Map<Guid, List<int>> serviceData;
  final double? latitude;
  final double? longitude;

  DiscoveredDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.lastSeen,
    required this.connectable,
    required this.manufacturerData,
    required this.serviceData,
    this.latitude,
    this.longitude,
  });
}