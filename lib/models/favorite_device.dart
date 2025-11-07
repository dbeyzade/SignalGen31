class FavoriteDevice {
  final String id;
  final String name;
  final String? customName;
  final DateTime addedAt;

  FavoriteDevice({
    required this.id,
    required this.name,
    this.customName,
    required this.addedAt,
  });

  String get displayName => customName ?? name;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'customName': customName,
        'addedAt': addedAt.toIso8601String(),
      };

  factory FavoriteDevice.fromJson(Map<String, dynamic> json) => FavoriteDevice(
        id: json['id'],
        name: json['name'],
        customName: json['customName'],
        addedAt: DateTime.parse(json['addedAt']),
      );
}
