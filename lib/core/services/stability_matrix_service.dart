import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final stabilityMatrixServiceProvider = Provider<StabilityMatrixService>((ref) {
  return StabilityMatrixService();
});

class StabilityMatrixService {
  static const String _prefKey = 'stability_matrix_path';

  Future<String?> getSavedPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey);
  }

  Future<bool> validatePath(String path) async {
    final dir = Directory(path);
    return await dir.exists();
  }

  Future<String?> selectPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select StabilityMatrix Folder (User Data)',
    );

    if (selectedDirectory != null) {
      // Basic validation: user might select "Data" folder or root folder
      // Let's rely on user selecting the correct one for now, or check for "Packages" inside?
      // For MVP, just save what they selected.
      await _savePath(selectedDirectory);
      return selectedDirectory;
    }
    return null;
  }

  Future<void> _savePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, path);
  }

  Future<void> clearPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  // Helper to resolve standard paths
  // Assuming the user selected the "Data" folder or a folder containing "Data"
  // StabilityMatrix Portable: Root -> Data
  // StabilityMatrix Installed: %AppData%\StabilityMatrix -> Data is usually inside or managed differently?
  // Let's assume user selects the folder that *contains* "Packages" or *is* "Data".
  // A robust check would be recursively looking for "Packages".

  Future<Directory?> getWildcardsDirectory(String basePath) async {
    // Common pattern: Data/Packages/.../extensions/sd-dynamic-prompts/wildcards
    // We need to find where "sd-dynamic-prompts" is.
    // It could be in any package (e.g. "Stable Diffusion WebUI Forge").
    // So we might search: basePath/Packages/*/extensions/sd-dynamic-prompts/wildcards

    final packagesDir = Directory('$basePath${Platform.pathSeparator}Packages');
    if (!await packagesDir.exists()) {
      // Maybe they selected 'Packages' directly?
      if (basePath.endsWith('Packages')) {
        return _findWildcardsInPackages(Directory(basePath));
      }
      // Maybe they selected Root and 'Data' is a subdir?
      final dataPackages = Directory(
        '$basePath${Platform.pathSeparator}Data${Platform.pathSeparator}Packages',
      );
      if (await dataPackages.exists()) {
        return _findWildcardsInPackages(dataPackages);
      }

      return null;
    }

    return _findWildcardsInPackages(packagesDir);
  }

  Future<Directory?> _findWildcardsInPackages(Directory packagesDir) async {
    try {
      if (!await packagesDir.exists()) return null;

      await for (final package in packagesDir.list()) {
        if (package is Directory) {
          // Look for extensions/sd-dynamic-prompts/wildcards
          final wildcardsDir = Directory(
            '${package.path}${Platform.pathSeparator}extensions${Platform.pathSeparator}sd-dynamic-prompts${Platform.pathSeparator}wildcards',
          );
          if (await wildcardsDir.exists()) {
            return wildcardsDir;
          }
        }
      }
    } catch (e) {
      // debugPrint('Error finding wildcards: $e');
    }
    return null;
  }
}
