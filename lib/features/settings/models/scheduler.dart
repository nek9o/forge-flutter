class Scheduler {
  final String name;
  final String label;

  Scheduler({required this.name, required this.label});

  factory Scheduler.fromJson(Map<String, dynamic> json) {
    return Scheduler(name: json['name'] ?? '', label: json['label'] ?? '');
  }
}
