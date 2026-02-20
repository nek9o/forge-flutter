import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';

/// システムリソースモニター
/// CPU, メモリ, GPU, VRAM の使用率をリアルタイムで表示
class SystemMonitor extends ConsumerStatefulWidget {
  const SystemMonitor({super.key});

  @override
  ConsumerState<SystemMonitor> createState() => _SystemMonitorState();
}

class _SystemMonitorState extends ConsumerState<SystemMonitor> {
  Timer? _timer;
  static const int _maxSamples = 300; // 約5分分 (1秒間隔)

  // データ履歴
  final List<double> _cpuHistory = [];
  final List<double> _memoryHistory = [];
  final List<double> _gpuHistory = [];
  final List<double> _vramHistory = [];

  // 最新の値
  double _cpuPercent = 0;
  double _memoryPercent = 0;
  double _memoryUsedGB = 0;
  double _memoryTotalGB = 0;
  double _gpuPercent = 0;
  double _vramUsedGB = 0;
  double _vramTotalGB = 0;
  bool _gpuAvailable = false;
  bool _initialized = false;

  // Linux CPU計算用
  int _prevTotal = 0;
  int _prevIdle = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (Platform.isWindows) {
      if (!_initialized) {
        // 初回実行時に実行ファイルのパスを解決
        await _resolveWindowsPaths();
      }
      // WindowsではCPU、メモリをまとめて取得して高速化
      await Future.wait([_fetchWindowsSystemStats(), _fetchGpu()]);
    } else {
      await Future.wait([_fetchCpu(), _fetchMemory(), _fetchGpu()]);
    }

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  String _powershellPath = 'powershell.exe';
  String _nvidiaSmiPath = 'nvidia-smi';
  String _typeperfPath = 'typeperf.exe';
  String _wmicPath = 'wmic.exe';

  Future<void> _resolveWindowsPaths() async {
    // 各コマンドの存在確認 (絶対パスを優先)
    _powershellPath = await _findExecutable(
      [
        r'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe',
        r'C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe',
        'powershell.exe',
      ],
      ['-NoProfile', '-Command', r'$true'],
    );

    _nvidiaSmiPath = await _findExecutable(
      [
        r'C:\Windows\System32\nvidia-smi.exe',
        r'C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe',
        'nvidia-smi',
      ],
      ['--help'],
    );

    _typeperfPath = await _findExecutable(
      [r'C:\Windows\System32\typeperf.exe', 'typeperf.exe'],
      ['-?'],
    );

    _wmicPath = await _findExecutable(
      [
        r'C:\Windows\System32\wbem\wmic.exe',
        r'C:\Windows\System32\wmic.exe',
        'wmic.exe',
      ],
      ['/?'],
    );

    debugPrint(
      'SystemMonitor: Resolved paths: PS=$_powershellPath, GPU=$_nvidiaSmiPath, TYPEPERF=$_typeperfPath, WMIC=$_wmicPath',
    );

    // メモリ総量を一度だけ取得
    await _fetchTotalMemory();
  }

  Future<void> _fetchTotalMemory() async {
    // WMICで取得
    try {
      final res = await Process.run(_wmicPath, [
        'OS',
        'get',
        'TotalVisibleMemorySize',
        '/value',
      ], runInShell: false);
      if (res.exitCode == 0) {
        final match = RegExp(
          r'TotalVisibleMemorySize=(\d+)',
        ).firstMatch(res.stdout);
        if (match != null) {
          final total = double.tryParse(match.group(1)!);
          if (total != null && total > 0) {
            _memoryTotalGB = total / 1024 / 1024;
            debugPrint('SystemMonitor: Total RAM (WMIC): $_memoryTotalGB GB');
            return;
          }
        }
      }
    } catch (_) {}

    // PowerShellでフォールバック
    try {
      final res = await Process.run(_powershellPath, [
        '-NoProfile',
        '-Command',
        '(Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize',
      ], runInShell: _powershellPath == 'powershell.exe');
      if (res.exitCode == 0) {
        final total = double.tryParse(res.stdout.toString().trim());
        if (total != null && total > 0) {
          _memoryTotalGB = total / 1024 / 1024;
          debugPrint('SystemMonitor: Total RAM (PS): $_memoryTotalGB GB');
        }
      }
    } catch (_) {}
  }

  Future<String> _findExecutable(
    List<String> paths,
    List<String> testArgs,
  ) async {
    for (final path in paths) {
      try {
        final res = await Process.run(path, testArgs);
        // typeperf -? は 0 以外を返すことがあるので、例外が起きなければOKとする場合もある
        if (res.exitCode == 0 ||
            (path.contains('typeperf') && res.stderr.toString().isEmpty)) {
          return path;
        }
      } catch (_) {}
    }
    return paths.last; // 見つからなければデフォルト（最後）を返す
  }

  Future<void> _fetchWindowsSystemStats() async {
    // 1. CPU情報の取得 (Typeperf > WMIC > PowerShell)
    bool cpuSuccess = false;

    // Typeperf
    try {
      final res = await Process.run(_typeperfPath, [
        r'\Processor(_Total)\% Processor Time',
        '-sc',
        '1',
      ], runInShell: false);
      if (res.exitCode == 0) {
        final output = res.stdout.toString();
        final lines = output.split('\n');
        if (lines.length >= 3) {
          final values = lines[2].split(',');
          if (values.length >= 2) {
            final val = double.tryParse(values[1].replaceAll('"', ''));
            if (val != null) {
              _cpuPercent = val;
              _addSample(_cpuHistory, _cpuPercent);
              cpuSuccess = true;
            }
          }
        }
      }
    } catch (_) {}

    if (!cpuSuccess) {
      // WMIC fallback for CPU
      try {
        final res = await Process.run(_wmicPath, [
          'cpu',
          'get',
          'loadpercentage',
          '/value',
        ], runInShell: false);
        if (res.exitCode == 0) {
          final match = RegExp(r'LoadPercentage=(\d+)').firstMatch(res.stdout);
          if (match != null) {
            _cpuPercent = double.tryParse(match.group(1)!) ?? 0;
            _addSample(_cpuHistory, _cpuPercent);
            cpuSuccess = true;
          }
        }
      } catch (_) {}
    }

    // 2. メモリ情報の取得 (Typeperf [Available] > WMIC > PowerShell)
    bool memSuccess = false;

    // Typeperf で Available KBytes を取得
    try {
      final res = await Process.run(_typeperfPath, [
        r'\Memory\Available KBytes',
        '-sc',
        '1',
      ], runInShell: false);
      if (res.exitCode == 0) {
        final output = res.stdout.toString();
        final lines = output.split('\n');
        if (lines.length >= 3) {
          final values = lines[2].split(',');
          if (values.length >= 2) {
            final availableKB = double.tryParse(values[1].replaceAll('"', ''));
            if (availableKB != null && _memoryTotalGB > 0) {
              final usedGB = _memoryTotalGB - (availableKB / 1024 / 1024);
              _memoryUsedGB = usedGB > 0 ? usedGB : 0;
              _memoryPercent = (_memoryUsedGB / _memoryTotalGB * 100);
              _addSample(_memoryHistory, _memoryPercent);
              memSuccess = true;
            }
          }
        }
      }
    } catch (_) {}

    // WMIC fallback for RAM
    if (!memSuccess) {
      try {
        final res = await Process.run(_wmicPath, [
          'OS',
          'get',
          'FreePhysicalMemory',
          '/value',
        ], runInShell: false);
        if (res.exitCode == 0) {
          final match = RegExp(
            r'FreePhysicalMemory=(\d+)',
          ).firstMatch(res.stdout);
          if (match != null && _memoryTotalGB > 0) {
            final freeKB = double.tryParse(match.group(1)!);
            if (freeKB != null) {
              final usedGB = _memoryTotalGB - (freeKB / 1024 / 1024);
              _memoryUsedGB = usedGB > 0 ? usedGB : 0;
              _memoryPercent = (_memoryUsedGB / _memoryTotalGB * 100);
              _addSample(_memoryHistory, _memoryPercent);
              memSuccess = true;
            }
          }
        }
      } catch (_) {}
    }

    // 3. PowerShell 最終フォールバック
    if (!cpuSuccess || !memSuccess) {
      try {
        final result = await Process.run(_powershellPath, [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-Command',
          r'$os = Get-CimInstance Win32_OperatingSystem; $cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average; "$([Math]::Round($cpu ?? 0));$($os.FreePhysicalMemory),$($os.TotalVisibleMemorySize)"',
        ], runInShell: _powershellPath == 'powershell.exe');

        if (result.exitCode == 0) {
          final output = result.stdout.toString().trim();
          final topParts = output.split(';');
          if (topParts.length == 2) {
            if (!cpuSuccess) {
              final cpuValue = double.tryParse(topParts[0]);
              if (cpuValue != null) {
                _cpuPercent = cpuValue;
                _addSample(_cpuHistory, cpuValue);
              }
            }
            if (!memSuccess) {
              final memParts = topParts[1].split(',');
              if (memParts.length == 2) {
                final freeKB = double.tryParse(memParts[0]);
                final totalKB = double.tryParse(memParts[1]);
                if (freeKB != null && totalKB != null && totalKB > 0) {
                  _memoryTotalGB = totalKB / 1024 / 1024;
                  _memoryUsedGB = (totalKB - freeKB) / 1024 / 1024;
                  _memoryPercent = (_memoryUsedGB / _memoryTotalGB * 100);
                  _addSample(_memoryHistory, _memoryPercent);
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('SystemMonitor: PowerShell fallback failed: $e');
      }
    }
  }

  Future<void> _fetchCpu() async {
    try {
      if (Platform.isLinux) {
        final lines = await File('/proc/stat').readAsLines();
        // 1行目: "cpu  2255 34 2290 22625563 6290 127 456"
        final parts = lines.first
            .split(RegExp(r'\s+'))
            .where((s) => s.isNotEmpty)
            .toList();
        if (parts.length >= 5 && parts[0] == 'cpu') {
          final user = int.parse(parts[1]);
          final nice = int.parse(parts[2]);
          final system = int.parse(parts[3]);
          final idle = int.parse(parts[4]);

          final total = user + nice + system + idle;
          final totalDelta = total - _prevTotal;
          final idleDelta = idle - _prevIdle;

          if (totalDelta > 0) {
            final usage = (totalDelta - idleDelta) / totalDelta * 100;
            _cpuPercent = usage;
            _addSample(_cpuHistory, _cpuPercent);
          }

          _prevTotal = total;
          _prevIdle = idle;
        }
      }
    } catch (_) {
      // CPU情報取得失敗
    }
  }

  Future<void> _fetchMemory() async {
    try {
      if (Platform.isLinux) {
        final lines = await File('/proc/meminfo').readAsLines();
        double? total;
        double? available;

        for (final line in lines) {
          if (line.startsWith('MemTotal:')) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length >= 2) {
              total = double.tryParse(parts[1]);
            }
          } else if (line.startsWith('MemAvailable:')) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length >= 2) {
              available = double.tryParse(parts[1]);
            }
          }
        }

        if (total != null && available != null && total > 0) {
          _memoryTotalGB = total / 1024 / 1024; // KB→GB
          _memoryUsedGB = (total - available) / 1024 / 1024;
          _memoryPercent = ((total - available) / total * 100);
          _addSample(_memoryHistory, _memoryPercent);
        }
      }
    } catch (_) {
      // メモリ情報取得失敗
    }
  }

  Future<void> _fetchGpu() async {
    try {
      final result = await Process.run(_nvidiaSmiPath, [
        '--query-gpu=utilization.gpu,memory.used,memory.total',
        '--format=csv,noheader,nounits',
      ], runInShell: _nvidiaSmiPath == 'nvidia-smi');

      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        // 出力例: "42, 4096, 8192"
        final parts = output.split(',').map((s) => s.trim()).toList();
        if (parts.length >= 3) {
          _gpuPercent = double.tryParse(parts[0]) ?? 0.0;
          _vramUsedGB = (double.tryParse(parts[1]) ?? 0) / 1024; // MB→GB
          _vramTotalGB = (double.tryParse(parts[2]) ?? 0) / 1024;
          final vramPercent = _vramTotalGB > 0
              ? (_vramUsedGB / _vramTotalGB * 100)
              : 0.0;

          _addSample(_gpuHistory, _gpuPercent);
          _addSample(_vramHistory, vramPercent);
          _gpuAvailable = true;
          return;
        }
      } else {
        // nvidia-smi が失敗した場合、GPUは利用不可とする
        if (_gpuAvailable) {
          debugPrint(
            'SystemMonitor: nvidia-smi failed with exit code ${result.exitCode}',
          );
        }
        _gpuAvailable = false;
      }
    } catch (e) {
      if (_gpuAvailable) {
        debugPrint('SystemMonitor: Exception when running nvidia-smi: $e');
      }
      _gpuAvailable = false;
    }
  }

  void _addSample(List<double> history, double value) {
    history.add(value);
    if (history.length > _maxSamples) {
      history.removeAt(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fTheme = FTheme.of(context);
    final locale = ref.watch(localeProvider);

    if (!_initialized) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: FProgress()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CPU
          _buildMetricRow(
            context,
            icon: PhosphorIcons.cpu(),
            label: L.of(locale, 'cpu'),
            value: '${_cpuPercent.toStringAsFixed(0)}%',
            percent: _cpuPercent,
            history: _cpuHistory,
            color: fTheme.colors.primary,
          ),
          const SizedBox(height: 10),
          // メモリ
          _buildMetricRow(
            context,
            icon: PhosphorIcons.memory(),
            label: L.of(locale, 'ram'),
            value:
                '${_memoryUsedGB.toStringAsFixed(1)} / ${_memoryTotalGB.toStringAsFixed(0)} GB',
            percent: _memoryPercent,
            history: _memoryHistory,
            color: const Color(0xFF4CAF50),
          ),
          if (_gpuAvailable) ...[
            const SizedBox(height: 10),
            // GPU
            _buildMetricRow(
              context,
              icon: PhosphorIcons.circuitry(),
              label: L.of(locale, 'gpu'),
              value: '${_gpuPercent.toStringAsFixed(0)}%',
              percent: _gpuPercent,
              history: _gpuHistory,
              color: const Color(0xFFFF9800),
            ),
            const SizedBox(height: 10),
            // VRAM
            _buildMetricRow(
              context,
              icon: PhosphorIcons.hardDrives(),
              label: L.of(locale, 'vram'),
              value:
                  '${_vramUsedGB.toStringAsFixed(1)} / ${_vramTotalGB.toStringAsFixed(0)} GB',
              percent: _vramTotalGB > 0
                  ? (_vramUsedGB / _vramTotalGB * 100)
                  : 0,
              history: _vramHistory,
              color: const Color(0xFFE040FB),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required PhosphorIconData icon,
    required String label,
    required String value,
    required double percent,
    required List<double> history,
    required Color color,
  }) {
    final fTheme = FTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ラベル行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                PhosphorIcon(
                  icon,
                  size: 14,
                  color: fTheme.colors.mutedForeground,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: fTheme.colors.mutedForeground,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                color: fTheme.colors.foreground,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // ミニグラフ
        SizedBox(
          height: 28,
          width: double.infinity,
          child: CustomPaint(
            painter: _SparklinePainter(
              data: history,
              maxSamples: _maxSamples,
              color: color,
              backgroundColor: fTheme.colors.muted,
            ),
          ),
        ),
      ],
    );
  }
}

/// ミニ折れ線グラフの描画
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final int maxSamples;
  final Color color;
  final Color backgroundColor;

  _SparklinePainter({
    required this.data,
    required this.maxSamples,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 背景
    final bgPaint = Paint()..color = backgroundColor.withAlpha(80);
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    );
    canvas.drawRRect(bgRect, bgPaint);

    if (data.isEmpty) return;

    // 折れ線
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 塗りつぶし
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withAlpha(60), color.withAlpha(5)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    final stepX = size.width / (maxSamples - 1);
    final startOffset = maxSamples - data.length;

    for (int i = 0; i < data.length; i++) {
      final x = (startOffset + i) * stepX;
      final y = size.height - (data[i] / 100.0 * size.height);
      final clampedY = y.clamp(1.0, size.height - 1);

      if (i == 0) {
        path.moveTo(x, clampedY);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, clampedY);
      } else {
        path.lineTo(x, clampedY);
        fillPath.lineTo(x, clampedY);
      }
    }

    // 塗りつぶしパスを閉じる
    final lastX = (startOffset + data.length - 1) * stepX;
    fillPath.lineTo(lastX, size.height);
    fillPath.close();

    canvas.save();
    canvas.clipRRect(bgRect);
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => true;
}
