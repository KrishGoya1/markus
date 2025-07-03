import 'package:flutter/material.dart';
import 'ble_scan_page.dart';
import 'BleRadarPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool isRadarView = false;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  void toggleView() {
    _fadeController.reverse().then((_) {
      setState(() => isRadarView = !isRadarView);
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isRadarView ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          isRadarView ? "Radar View" : "Nearby Devices",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isRadarView ? Colors.black : Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: toggleView,
            icon: Icon(isRadarView ? Icons.list : Icons.radar),
            tooltip: isRadarView ? 'Switch to List View' : 'Switch to Radar View',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeController,
        child: isRadarView ? const BleRadarPage() : const BleMapperPage(),
      ),
    );
  }
}
