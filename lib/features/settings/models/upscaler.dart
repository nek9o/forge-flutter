class Upscaler {
  final String name;
  final String? modelPath;

  Upscaler({required this.name, this.modelPath});

  factory Upscaler.fromJson(Map<String, dynamic> json) {
    return Upscaler(
      name: json['name'] ?? '',
      modelPath: json['model_path'],
    );
  }
}
