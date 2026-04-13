class Activity {
  final String title;
  final String description;
  final String address;
  final double lat;
  final double lng;

  // 🔥 ADD THIS
  final String? photoUrl;

  Activity({
    required this.title,
    required this.description,
    required this.address,
    required this.lat,
    required this.lng,
    this.photoUrl,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),

      // 🔥 MAP PHOTO
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'address': address,
      'lat': lat,
      'lng': lng,
      'photoUrl': photoUrl,
    };
  }
}
