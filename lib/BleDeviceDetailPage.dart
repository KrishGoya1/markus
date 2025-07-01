// ignore: file_names
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleDeviceDetailPage extends StatelessWidget {
  final ScanResult result;

  const BleDeviceDetailPage({super.key, required this.result});

  String _formatManufacturerData(Map<int, List<int>> data) {
    return data.entries
        .map((e) =>
            "${e.key.toRadixString(16).padLeft(4, '0')}: ${e.value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}")
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final adv = result.advertisementData;

    return Scaffold(
      appBar: AppBar(title: Text(result.device.platformName.isNotEmpty
          ? result.device.platformName
          : adv.advName.isNotEmpty
              ? adv.advName
              : "(Unnamed Device)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Device ID: ${result.device.remoteId}", style: TextStyle(fontSize: 16)),
            Text("RSSI: ${result.rssi}"),
            if (adv.advName.isNotEmpty) Text("Local Name: ${adv.advName}"),
            Text("Connectable: ${adv.connectable}"),
            if (adv.txPowerLevel != null) Text("TX Power: ${adv.txPowerLevel} dBm"),
            if (adv.serviceUuids.isNotEmpty)
              Text("Service UUIDs:\n${adv.serviceUuids.join('\n')}"),
            if (adv.serviceData.isNotEmpty)
              Text("Service Data:\n${adv.serviceData}"),
            if (adv.manufacturerData.isNotEmpty)
              Text("Manufacturer Data:\n${_formatManufacturerData(adv.manufacturerData)}"),
          ],
        ),
      ),
    );
  }
}
