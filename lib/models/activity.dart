class Activity {
  final String title;
  final String description;
  final String group;
  final String budget;
  final String address;

  Activity({
    required this.title,
    required this.description,
    required this.group,
    required this.budget,
    this.address = "", // 🔥 NOT REQUIRED ANYMORE
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      title: json['title'] ?? "",
      description: json['description'] ?? "",
      group: json['group'] ?? "",
      budget: json['budget'] ?? "",
      address: json['address'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "description": description,
      "group": group,
      "budget": budget,
      "address": address,
    };
  }
}