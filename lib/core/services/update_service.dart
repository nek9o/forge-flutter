import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

class UpdateInfo {
  final bool hasUpdate;
  final Version latestVersion;
  final String releaseUrl;

  UpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.releaseUrl,
  });
}

class UpdateService {
  final Dio _dio = Dio(
    // タイムアウトを明示的に設定し、遅いネットワーク環境でのUIブロックを防ぐ
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  static const String _repoUrl = 'https://api.github.com/repos/nek9o/forge-flutter/releases';

  Future<UpdateInfo> checkForUpdates() async {
    try {
      // 現在のバージョンを取得
      // packageInfo.version は "YYYY.M.D" 形式、buildNumber は連番のみ
      // "YYYY.M.D+SEQ" の形に結合してパースする
      final packageInfo = await PackageInfo.fromPlatform();
      // version が既に "+" を含む場合に備え、"+" 以前のみを使用する
      final versionOnly = packageInfo.version.split('+').first;
      final currentVersionString = '$versionOnly+${packageInfo.buildNumber}';
      final currentVersion = Version.parse(currentVersionString);

      // 最新のリリースを取得 (/releases/latest はプレリリースを無視するため、/releases を使用)
      final response = await _dio.get(_repoUrl);
      if (response.statusCode == 200) {
        final List<dynamic> releases = response.data;
        if (releases.isEmpty) {
          return UpdateInfo(
            hasUpdate: false,
            latestVersion: Version.none,
            releaseUrl: '',
          );
        }

        // GitHub APIは作成日時の降順なので、最初に見つかったdraftでないものが最新
        Map<String, dynamic>? latestRelease;
        for (final release in releases) {
          if (release['draft'] == false) {
            latestRelease = release as Map<String, dynamic>;
            break;
          }
        }

        if (latestRelease == null) {
          return UpdateInfo(
            hasUpdate: false,
            latestVersion: Version.none,
            releaseUrl: '',
          );
        }

        final tagName = latestRelease['tag_name'] as String;
        final releaseUrl = latestRelease['html_url'] as String;

        // "2026.4.9-1" の "-" を "+" に置換してビルド番号として扱う
        // 万が一 "v" から始まるタグ名の場合は取り除く
        final cleanTagName = tagName.startsWith('v') ? tagName.substring(1) : tagName;
        final latestVersionString = cleanTagName.replaceAll('-', '+');
        final latestVersion = Version.parse(latestVersionString);

        // pub_semverはビルド番号も含めて比較してくれる
        final hasUpdate = latestVersion > currentVersion;

        return UpdateInfo(
          hasUpdate: hasUpdate,
          latestVersion: latestVersion,
          releaseUrl: releaseUrl,
        );
      }
    } catch (e) {
      // 通信失敗やパースエラーは握りつぶし、アップデートなしとして扱う
      // リリースビルドではログを出力しない
      debugPrint('Update check failed: $e');
    }

    // 失敗した場合やアップデートがない場合は hasUpdate: false を返す
    return UpdateInfo(
      hasUpdate: false,
      latestVersion: Version.none,
      releaseUrl: '',
    );
  }
}

final updateServiceProvider = Provider((ref) => UpdateService());

final updateCheckFutureProvider = FutureProvider<UpdateInfo>((ref) async {
  final service = ref.watch(updateServiceProvider);
  return service.checkForUpdates();
});
