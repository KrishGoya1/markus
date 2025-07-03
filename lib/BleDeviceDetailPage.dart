// ignore: file_names
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_device_identifier.dart';

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
    final deviceName = BleDeviceIdentifier.getDeviceName(result);

    return Scaffold(
      appBar: AppBar(title: Text(deviceName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Device Information", 
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text("Device ID: ${result.device.remoteId.str}"),
                    Text("RSSI: ${result.rssi} dBm"),
                    if (result.device.platformName.isNotEmpty) 
                      Text("Platform Name: ${result.device.platformName}"),
                    if (adv.advName.isNotEmpty) 
                      Text("Advertised Name: ${adv.advName}"),
                    Text("Connectable: ${adv.connectable ? 'Yes' : 'No'}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (adv.txPowerLevel != null) Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Signal Information", 
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text("TX Power: ${adv.txPowerLevel} dBm"),
                  ],
                ),
              ),
            ),
            if (adv.serviceUuids.isNotEmpty) ...[  
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Service UUIDs", 
                        style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      ...adv.serviceUuids.map((uuid) => Text(uuid.toString())),
                    ],
                  ),
                ),
              ),
            ],
            if (adv.serviceData.isNotEmpty) ...[  
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Service Data", 
                        style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      ...adv.serviceData.entries.map((e) => Text(
                        "${e.key}: ${e.value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}"
                      )),
                    ],
                  ),
                ),
              ),
            ],
            if (adv.manufacturerData.isNotEmpty) ...[  
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Manufacturer Data", 
                        style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(_formatManufacturerData(adv.manufacturerData)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
