class GenerationSettings {
  final String samplerName;
  final int width;
  final int height;
  final int steps;
  final double cfgScale;
  final int seed;
  final String? scheduler;
  final bool saveImages;
  final int batchSize;
  final int batchCount;
  final String sdMode;

  GenerationSettings({
    this.samplerName = 'Euler a',
    this.width = 512,
    this.height = 512,
    this.steps = 20,
    this.cfgScale = 7.0,
    this.seed = -1,
    this.scheduler = 'Automatic',
    this.saveImages = true,
    this.batchSize = 1,
    this.batchCount = 1,
    this.sdMode = 'SD',
  });

  GenerationSettings copyWith({
    String? samplerName,
    int? width,
    int? height,
    int? steps,
    double? cfgScale,
    int? seed,
    String? scheduler,
    bool? saveImages,
    int? batchSize,
    int? batchCount,
    String? sdMode,
  }) {
    return GenerationSettings(
      samplerName: samplerName ?? this.samplerName,
      width: width ?? this.width,
      height: height ?? this.height,
      steps: steps ?? this.steps,
      cfgScale: cfgScale ?? this.cfgScale,
      seed: seed ?? this.seed,
      scheduler: scheduler ?? this.scheduler,
      saveImages: saveImages ?? this.saveImages,
      batchSize: batchSize ?? this.batchSize,
      batchCount: batchCount ?? this.batchCount,
      sdMode: sdMode ?? this.sdMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sampler_name': samplerName,
      'width': width,
      'height': height,
      'steps': steps,
      'cfg_scale': cfgScale,
      'seed': seed,
      'scheduler': scheduler,
      'save_images': saveImages,
      'batch_size': batchSize,
      'batch_count': batchCount,
      'sd_mode': sdMode,
    };
  }
}
