import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'discovered_device.dart';

class RadarView extends StatelessWidget {
  final List<DiscoveredDevice> devices;
  final double centerLat;
  final double centerLon;

  const RadarView({
    super.key,
    required this.devices,
    required this.centerLat,
    required this.centerLon,
  });

  double _getBearing(double lat1, double lon1, double lat2, double lon2) {
    lat1 = lat1 * math.pi / 180;
    lat2 = lat2 * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    var bearing = math.atan2(y, x);
    bearing = bearing * 180 / math.pi;
    bearing = (bearing + 360) % 360;
    return bearing;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: RadarPainter(
            devices: devices
                .where((d) => d.latitude != null && d.longitude != null)
                .map((d) => DevicePosition(
                      name: d.name,
                      bearing: _getBearing(
                        centerLat,
                        centerLon,
                        d.latitude!,
                        d.longitude!,
                      ),
                      rssi: d.rssi,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class DevicePosition {
  final String name;
  final double bearing;
  final int rssi;

  DevicePosition({
    required this.name,
    required this.bearing,
    required this.rssi,
  });
}

class RadarPainter extends CustomPainter {
  final List<DevicePosition> devices;

  RadarPainter({required this.devices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw radar circles
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * i / 4, paint);
    }

    // Draw direction lines
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
        paint,
      );
    }

    // Draw direction labels
    final directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      textPainter.text = TextSpan(
        text: directions[i],
        style: const TextStyle(color: Colors.blue, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx + (radius + 20) * math.cos(angle) - textPainter.width / 2,
          center.dy + (radius + 20) * math.sin(angle) - textPainter.height / 2,
        ),
      );
    }

    // Draw devices
    final devicePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (final device in devices) {
      final angle = device.bearing * math.pi / 180;
      final point = Offset(
        center.dx + radius * 0.8 * math.cos(angle),
        center.dy + radius * 0.8 * math.sin(angle),
      );

      canvas.drawCircle(point, 5, devicePaint);

      textPainter.text = TextSpan(
        text: device.name,
        style: const TextStyle(color: Colors.black, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          point.dx - textPainter.width / 2,
          point.dy - textPainter.height - 10,
        ),
      );
    }

    // Draw center point
    canvas.drawCircle(
      center,
      8,
      Paint()..color = Colors.red,
    );
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) => true;
}