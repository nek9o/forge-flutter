class SDModel {
  final String title;
  final String modelName;
  final String hash;
  final String sha256;
  final String filename;
  final String config;

  SDModel({
    required this.title,
    required this.modelName,
    required this.hash,
    required this.sha256,
    required this.filename,
    required this.config,
  });

  factory SDModel.fromJson(Map<String, dynamic> json) {
    return SDModel(
      title: json['title'] ?? '',
      modelName: json['model_name'] ?? '',
      hash: json['hash'] ?? '',
      sha256: json['sha256'] ?? '',
      filename: json['filename'] ?? '',
      config: json['config'] ?? '',
    );
  }
}
