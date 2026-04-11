class Activity {
  final String title;
  final String description;
  final String address;
  final double lat;
  final double lng;

  Activity({
    required this.title,
    required this.description,
    required this.address,
    required this.lat,
    required this.lng,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "description": description,
      "address": address,
      "lat": lat,
      "lng": lng,
    };
  }
}