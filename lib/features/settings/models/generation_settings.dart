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
  final bool uiDebugMode;
  final bool enableHires;
  final String? hiresUpscaler;
  final int hiresSteps;
  final double denoisingStrength;
  final double hrScale;

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
    this.uiDebugMode = false,
    this.enableHires = false,
    this.hiresUpscaler,
    this.hiresSteps = 20,
    this.denoisingStrength = 0.7,
    this.hrScale = 2.0,
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
    bool? uiDebugMode,
    bool? enableHires,
    String? hiresUpscaler,
    int? hiresSteps,
    double? denoisingStrength,
    double? hrScale,
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
      uiDebugMode: uiDebugMode ?? this.uiDebugMode,
      enableHires: enableHires ?? this.enableHires,
      hiresUpscaler: hiresUpscaler ?? this.hiresUpscaler,
      hiresSteps: hiresSteps ?? this.hiresSteps,
      denoisingStrength: denoisingStrength ?? this.denoisingStrength,
      hrScale: hrScale ?? this.hrScale,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'sampler_name': samplerName,
      'width': width,
      'height': height,
      'steps': steps,
      'cfg_scale': cfgScale,
      'seed': seed,
      'save_images': saveImages,
      'batch_size': batchSize,
      'n_iter': batchCount,
      'sd_mode': sdMode,
      'ui_debug_mode': uiDebugMode,
      'enable_hr': enableHires,
      'denoising_strength': denoisingStrength,
      'hr_scale': hrScale,
      'hr_second_pass_steps': hiresSteps,
    };

    if (enableHires) {
      map['hr_additional_modules'] = ["Use same choices"];
      if (hiresUpscaler == null || hiresUpscaler!.isEmpty) {
        map['hr_upscaler'] = 'Latent';
      } else {
        map['hr_upscaler'] = hiresUpscaler!;
      }
    }

    final schedulerValue = scheduler;
    if (schedulerValue != null &&
        schedulerValue.isNotEmpty &&
        schedulerValue != 'Automatic') {
      map['scheduler'] = schedulerValue;
    }

    return map;
  }
}
