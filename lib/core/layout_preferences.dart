import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LayoutPreferences {
  static const String _settingsWidthKey = 'settings_width';
  static const String _previewSplitKey = 'preview_split';
  static const String _previewVerticalSplitKey = 'preview_vertical_split';
  static const String _promptSplitKey = 'prompt_split';
  static const String _accordionExpandedKey = 'accordion_expanded';
  static const String _previewTabIndexKey = 'preview_tab_index';
  static const String _settingsExpandedKey = 'settings_expanded';
  static const String _showMonitorKey = 'show_monitor';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Settings pane width
  static double getSettingsWidth() {
    return _prefs?.getDouble(_settingsWidthKey) ?? 280.0;
  }

  static Future<void> setSettingsWidth(double width) async {
    await init();
    await _prefs?.setDouble(_settingsWidthKey, width);
  }

  // Preview/Prompt split ratio
  static double getPreviewSplit() {
    return _prefs?.getDouble(_previewSplitKey) ?? 0.5;
  }

  static Future<void> setPreviewSplit(double split) async {
    await init();
    await _prefs?.setDouble(_previewSplitKey, split);
  }

  // Preview vertical split ratio
  static double getPreviewVerticalSplit() {
    return _prefs?.getDouble(_previewVerticalSplitKey) ?? 0.5;
  }

  static Future<void> setPreviewVerticalSplit(double split) async {
    await init();
    await _prefs?.setDouble(_previewVerticalSplitKey, split);
  }

  // Prompt split ratio
  static double getPromptSplit() {
    return _prefs?.getDouble(_promptSplitKey) ?? 0.6;
  }

  static Future<void> setPromptSplit(double split) async {
    await init();
    await _prefs?.setDouble(_promptSplitKey, split);
  }

  // Accordion expanded state
  static Set<int> getAccordionExpanded() {
    final jsonString = _prefs?.getString(_accordionExpandedKey);
    if (jsonString != null) {
      try {
        final List<dynamic> list = json.decode(jsonString);
        return Set<int>.from(list.map((e) => e as int));
      } catch (e) {
        return {0, 1}; // デフォルト値
      }
    }
    return {0, 1}; // デフォルト値
  }

  static Future<void> setAccordionExpanded(Set<int> expanded) async {
    await init();
    final jsonString = json.encode(expanded.toList());
    await _prefs?.setString(_accordionExpandedKey, jsonString);
  }

  // Preview tab index
  static int getPreviewTabIndex() {
    return _prefs?.getInt(_previewTabIndexKey) ?? 0;
  }

  static Future<void> setPreviewTabIndex(int index) async {
    await init();
    await _prefs?.setInt(_previewTabIndexKey, index);
  }

  // Settings expanded state
  static bool getSettingsExpanded() {
    return _prefs?.getBool(_settingsExpandedKey) ?? true;
  }

  static Future<void> setSettingsExpanded(bool expanded) async {
    await init();
    await _prefs?.setBool(_settingsExpandedKey, expanded);
  }

  // Show monitor state
  static bool getShowMonitor() {
    return _prefs?.getBool(_showMonitorKey) ?? false;
  }

  static Future<void> setShowMonitor(bool show) async {
    await init();
    await _prefs?.setBool(_showMonitorKey, show);
  }

  // Clear all preferences
  static Future<void> clearAll() async {
    await init();
    await _prefs?.clear();
  }
}
