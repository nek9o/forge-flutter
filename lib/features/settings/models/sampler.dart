class Sampler {
  final String name;
  final List<String> aliases;
  final Map<String, dynamic> options;

  Sampler({required this.name, required this.aliases, required this.options});

  factory Sampler.fromJson(Map<String, dynamic> json) {
    return Sampler(
      name: json['name'] ?? '',
      aliases: List<String>.from(json['aliases'] ?? []),
      options: Map<String, dynamic>.from(json['options'] ?? {}),
    );
  }
}
