import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mbtiles/mbtiles.dart';

class OfflineMapScreen extends StatefulWidget {
  const OfflineMapScreen({super.key});

  @override
  State<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends State<OfflineMapScreen> {
  MbTilesTileProvider? _tileProvider;

  @override
  void initState() {
    super.initState();
    _prepareMap();
  }

  Future<void> _prepareMap() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/tamil_nadu.mbtiles';

    // Copy map from assets → device storage (once)
    if (!File(filePath).existsSync()) {
      final data = await rootBundle.load('assets/maps/tamil_nadu.mbtiles');
      final bytes = data.buffer.asUint8List();
      await File(filePath).writeAsBytes(bytes);
    }

    // Open MBTiles SQLite database
    final mbtiles = MbTiles(mbtilesPath: filePath);
    final provider = MbTilesTileProvider(
      mbtiles: mbtiles,
    );

    setState(() => _tileProvider = provider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF300000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF300000),
        elevation: 0,
        title: const Text("Parking Map", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF0000), Color(0xFF300000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _tileProvider == null
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(11.0168, 76.9558),
                    initialZoom: 6,
                  ),
                  children: [
                    TileLayer(tileProvider: _tileProvider!),
                  ],
                ),
              ),
      ),
    );
  }
}
