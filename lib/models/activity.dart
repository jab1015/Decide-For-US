class Activity {
  final String title;
  final String description;
  final String group;
  final String budget;

  Activity({
    required this.title,
    required this.description,
    required this.group,
    required this.budget,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      group: json['group'] ?? '',
      budget: json['budget'] ?? '',
    );
  }
}