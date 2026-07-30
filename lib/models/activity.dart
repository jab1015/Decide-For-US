class Activity {
  const Activity({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.address,
    required this.lat,
    required this.lng,
    this.photoUrl,
    this.eventUrl,
    this.eventStart,
    this.eventLocalDate,
    this.eventLocalTime,
    this.venueName,
    this.source,
    this.companion,
    this.companionDistanceMiles,
    this.searchRadiusMiles,
  });

  final String id;
  final String category;
  final String title;
  final String description;
  final String address;
  final double lat;
  final double lng;
  final String? photoUrl;
  final String? eventUrl;
  final DateTime? eventStart;
  final String? eventLocalDate;
  final String? eventLocalTime;
  final String? venueName;
  final String? source;
  final Activity? companion;
  final double? companionDistanceMiles;
  final int? searchRadiusMiles;

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] ?? json['place_id'] ?? '',
      category: json['category'] ?? 'activity',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      photoUrl: json['photoUrl'],
      eventUrl: json['eventUrl'],
      eventStart: DateTime.tryParse(json['eventStart']?.toString() ?? ''),
      eventLocalDate: json['eventLocalDate'],
      eventLocalTime: json['eventLocalTime'],
      venueName: json['venueName'],
      source: json['source'],
      companion: json['companion'] is Map<String, dynamic>
          ? Activity.fromJson(json['companion'] as Map<String, dynamic>)
          : null,
      companionDistanceMiles: (json['companionDistanceMiles'] as num?)
          ?.toDouble(),
      searchRadiusMiles: (json['searchRadiusMiles'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'title': title,
    'description': description,
    'address': address,
    'lat': lat,
    'lng': lng,
    'photoUrl': photoUrl,
    'eventUrl': eventUrl,
    'eventStart': eventStart?.toIso8601String(),
    'eventLocalDate': eventLocalDate,
    'eventLocalTime': eventLocalTime,
    'venueName': venueName,
    'source': source,
    'companion': companion?.toJson(),
    'companionDistanceMiles': companionDistanceMiles,
    'searchRadiusMiles': searchRadiusMiles,
  };
}

