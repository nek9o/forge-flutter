class Lora {
  final String name;
  final String? alias;
  final String? path;
  final String? metadata;

  Lora({required this.name, this.alias, this.path, this.metadata});

  factory Lora.fromJson(Map<String, dynamic> json) {
    return Lora(
      name: json['name'] ?? '',
      alias: json['alias'],
      path: json['path'],
      metadata: json['metadata']?.toString(),
    );
  }
}
