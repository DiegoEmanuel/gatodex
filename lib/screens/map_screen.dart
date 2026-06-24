import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../app_theme.dart';
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
    if (_cats.isEmpty) return const LatLng(-23.5505, -46.6333);
    final lat = _cats.map((c) => c.latitude).reduce((a, b) => a + b) / _cats.length;
    final lng = _cats.map((c) => c.longitude).reduce((a, b) => a + b) / _cats.length;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GC.bgDeep,
      appBar: AppBar(
        backgroundColor: GC.bgDeep,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Text('🗺️', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'Mapa de Gatos',
              style: TextStyle(
                color: GC.gold,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  GC.gold.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
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
                    width: isSelected ? 56 : 44,
                    height: isSelected ? 56 : 44,
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = cat),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSelected
                                ? [GC.gold, const Color(0xFFFFB300)]
                                : [GC.purple, GC.bgElevated],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? GC.gold : GC.purpleLight,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isSelected ? GC.gold : GC.purple).withValues(alpha: 0.5),
                              blurRadius: isSelected ? 12 : 6,
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [GC.bgElevated, GC.bgCard],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GC.gold.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: GC.purple.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(cat.imagePath),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 72,
                  height: 72,
                  color: GC.bgElevated,
                  child: const Center(child: Text('🐈', style: TextStyle(fontSize: 32))),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: GC.gold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${cat.entryNumber.toString().padLeft(3, '0')}',
                          style: const TextStyle(
                            color: Color(0xFF1A0050),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (cat.name != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat.name!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '📍 ${cat.latitude.toStringAsFixed(5)}, ${cat.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(color: GC.textMuted, fontSize: 11),
                  ),
                  Text(
                    '📅 ${cat.capturedAt.day.toString().padLeft(2, '0')}/${cat.capturedAt.month.toString().padLeft(2, '0')}/${cat.capturedAt.year}',
                    style: const TextStyle(color: GC.textMuted, fontSize: 11),
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [GC.bgElevated, GC.bgCard],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GC.gold.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: GC.purple.withValues(alpha: 0.3), blurRadius: 20),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🗺️', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Nenhum gato no mapa ainda',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'Capture gatos com GPS para vê-los aqui.',
              style: TextStyle(color: GC.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
