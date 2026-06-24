import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/cat_entry.dart';
import '../services/database_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<CatEntry> _cats = [];
  CatEntry? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await DatabaseService().getAll();
    if (mounted) setState(() => _cats = cats.where((c) => c.latitude != 0.0 || c.longitude != 0.0).toList());
  }

  LatLng get _center {
    if (_cats.isEmpty) return const LatLng(-23.5505, -46.6333); // São Paulo default
    final lat = _cats.map((c) => c.latitude).reduce((a, b) => a + b) / _cats.length;
    final lng = _cats.map((c) => c.longitude).reduce((a, b) => a + b) / _cats.length;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Text('🗺️', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'Mapa de Gatos',
              style: TextStyle(
                color: Color(0xFFFF8C00),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _cats.isEmpty ? 12 : 15,
              onTap: (_, _) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gatodex.app',
              ),
              MarkerLayer(
                markers: _cats.map((cat) {
                  final isSelected = _selected?.id == cat.id;
                  return Marker(
                    point: LatLng(cat.latitude, cat.longitude),
                    width: isSelected ? 52 : 40,
                    height: isSelected ? 52 : 40,
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = cat),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFF8C00) : const Color(0xFFFF8C00).withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🐱', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          if (_selected != null) _buildInfoCard(_selected!),
          if (_cats.isEmpty) _buildEmptyOverlay(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(CatEntry cat) {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF8C00).withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(cat.imagePath),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFF0F3460),
                  child: const Center(child: Text('🐈', style: TextStyle(fontSize: 32))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gato #${cat.entryNumber.toString().padLeft(3, '0')}',
                    style: const TextStyle(
                      color: Color(0xFFFF8C00),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📍 ${cat.latitude.toStringAsFixed(5)}, ${cat.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    '📅 ${cat.capturedAt.day.toString().padLeft(2, '0')}/${cat.capturedAt.month.toString().padLeft(2, '0')}/${cat.capturedAt.year}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOverlay() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🗺️', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Nenhum gato no mapa ainda',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Capture gatos com GPS para vê-los aqui.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
