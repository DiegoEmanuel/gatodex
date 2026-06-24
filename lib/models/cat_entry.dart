class CatEntry {
  final int? id;
  final String imagePath;
  final double latitude;
  final double longitude;
  final DateTime capturedAt;
  final int entryNumber;
  final String? name;

  const CatEntry({
    this.id,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    required this.entryNumber,
    this.name,
  });

  CatEntry copyWith({String? name}) => CatEntry(
        id: id,
        imagePath: imagePath,
        latitude: latitude,
        longitude: longitude,
        capturedAt: capturedAt,
        entryNumber: entryNumber,
        name: name ?? this.name,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'image_path': imagePath,
        'latitude': latitude,
        'longitude': longitude,
        'captured_at': capturedAt.toIso8601String(),
        'entry_number': entryNumber,
        'name': name,
      };

  factory CatEntry.fromMap(Map<String, dynamic> map) => CatEntry(
        id: map['id'] as int?,
        imagePath: map['image_path'] as String,
        latitude: map['latitude'] as double,
        longitude: map['longitude'] as double,
        capturedAt: DateTime.parse(map['captured_at'] as String),
        entryNumber: map['entry_number'] as int,
        name: map['name'] as String?,
      );
}
