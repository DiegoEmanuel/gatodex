class CatEntry {
  final int? id;
  final String imagePath;
  final double latitude;
  final double longitude;
  final DateTime capturedAt;
  final int entryNumber;
  final String? name;
  final String? cardName;
  final String? rarity;
  final String? element;
  final int? power;
  final int? agility;
  final int? charisma;
  final String? ability;
  final String? cardImageUrl;

  bool get hasCard => rarity != null;

  const CatEntry({
    this.id,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    required this.entryNumber,
    this.name,
    this.cardName,
    this.rarity,
    this.element,
    this.power,
    this.agility,
    this.charisma,
    this.ability,
    this.cardImageUrl,
  });

  CatEntry copyWith({
    String? name,
    String? cardName,
    String? rarity,
    String? element,
    int? power,
    int? agility,
    int? charisma,
    String? ability,
    String? cardImageUrl,
  }) =>
      CatEntry(
        id: id,
        imagePath: imagePath,
        latitude: latitude,
        longitude: longitude,
        capturedAt: capturedAt,
        entryNumber: entryNumber,
        name: name ?? this.name,
        cardName: cardName ?? this.cardName,
        rarity: rarity ?? this.rarity,
        element: element ?? this.element,
        power: power ?? this.power,
        agility: agility ?? this.agility,
        charisma: charisma ?? this.charisma,
        ability: ability ?? this.ability,
        cardImageUrl: cardImageUrl ?? this.cardImageUrl,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'image_path': imagePath,
        'latitude': latitude,
        'longitude': longitude,
        'captured_at': capturedAt.toIso8601String(),
        'entry_number': entryNumber,
        'name': name,
        'card_name': cardName,
        'rarity': rarity,
        'element': element,
        'power': power,
        'agility': agility,
        'charisma': charisma,
        'ability': ability,
        'card_image_url': cardImageUrl,
      };

  factory CatEntry.fromMap(Map<String, dynamic> map) => CatEntry(
        id: map['id'] as int?,
        imagePath: map['image_path'] as String,
        latitude: map['latitude'] as double,
        longitude: map['longitude'] as double,
        capturedAt: DateTime.parse(map['captured_at'] as String),
        entryNumber: map['entry_number'] as int,
        name: map['name'] as String?,
        cardName: map['card_name'] as String?,
        rarity: map['rarity'] as String?,
        element: map['element'] as String?,
        power: map['power'] as int?,
        agility: map['agility'] as int?,
        charisma: map['charisma'] as int?,
        ability: map['ability'] as String?,
        cardImageUrl: map['card_image_url'] as String?,
      );
}
