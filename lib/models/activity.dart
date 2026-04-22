class Activity {
  final String id; // 🔥 UNIQUE ID (Google place_id)
  final String title;
  final String description;
  final String address;
  final double lat;
  final double lng;
  final String? photoUrl;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.lat,
    required this.lng,
    this.photoUrl,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] ?? json['place_id'] ?? json['title'], // fallback safe
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'address': address,
      'lat': lat,
      'lng': lng,
      'photoUrl': photoUrl,
    };
  }
}
