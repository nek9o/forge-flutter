import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 対応言語
enum AppLocale { ja, en }

/// 現在の言語設定プロバイダー
final localeProvider = StateProvider<AppLocale>((ref) => AppLocale.ja);

/// ローカライズ文字列を取得するヘルパー
class L {
  static String of(AppLocale locale, String key) {
    return _strings[locale]?[key] ?? _strings[AppLocale.en]?[key] ?? key;
  }

  static const Map<AppLocale, Map<String, String>> _strings = {
    AppLocale.ja: _ja,
    AppLocale.en: _en,
  };

  // ── 日本語 ──
  static const _ja = {
    // サイドバー
    'settings_panel': '設定パネル',
    'system_monitor': 'システムモニター',
    'license_info': 'ライセンス情報',
    'language': '言語',

    // 設定ペイン
    'settings': '設定',
    'detailed_settings': '詳細設定',
    'api_settings': 'API 設定',
    'api_url': 'API URL',
    'ui_debug_mode': 'UIデバッグモード',
    'model_sampling': 'モデル & サンプリング',
    'model': 'モデル',
    'select_model': 'モデルを選択',
    'sampler': 'サンプラー',
    'scheduler': 'スケジューラ',
    'auto': '自動',
    'sampling_steps': 'サンプリングステップ数',
    'cfg_scale': 'CFGスケール',
    'image_settings': '画像設定',
    'width': '幅',
    'height': '高さ',
    'batch_size': 'バッチサイズ',
    'batch_count': 'バッチ回数',
    'seed': 'シード',
    'seed_hint': '-1 (ランダム)',
    'extensions_others': '拡張機能 & その他',
    'save_to_server': 'サーバーに保存',
    'browse_lora': 'LoRAをブラウズ',
    'error': 'エラー',
    'loading': '読み込み中...',

    // プロンプト
    'prompt': 'プロンプト',
    'negative_prompt': 'ネガティブプロンプト',
    'prompt_hint': 'プロンプトを入力... (カンマで区切るとチップに変換)',
    'negative_prompt_hint': 'ネガティブプロンプトを入力... (カンマで区切るとチップに変換)',
    'edit_chip': 'チップを編集',
    'cancel': 'キャンセル',
    'save': '保存',
    'show_hints': 'ヒントを表示',
    'weight': '重み',

    'clear_prompt': 'プロンプトをクリア',
    'clear': 'クリア',
    'select_all': '全て選択',
    'hint': 'ヒント',
    'prompt_no_chips': 'チップがありません。上のフィールドにプロンプトを入力してください。',
    'negative_prompt_no_chips': 'チップがありません。上のフィールドにネガティブプロンプトを入力してください。',
    'weight_range_helper': '0.1 ~ 5.0',
    'png_info_tab': 'PNG Info (D&D)',
    'detailed_settings_tooltip': '詳細設定',

    // プレビュー
    'generation_preview': '生成プレビュー',
    'png_info': 'PNG Info',
    'fullscreen': 'フルスクリーン表示',
    'close_image': '画像を閉じる',
    'send_to_txt2img': 'Txt2Imgに送信',
    'params_sent': 'パラメータをTxt2Imgに送信しました',
    'file_read_error': 'ファイル読み込みエラー',
    'generate': '生成',
    'interrupt': '中断',
    'no_image': 'まだ画像が生成されていません',
    'tap_generate': '「生成」ボタンを押して画像を作りましょう',
    'drag_drop_png': 'PNGファイルをドロップしてメタデータを確認',
    'drop_image_here': 'ここに画像をドロップ',

    // LoRAブラウザ
    'lora_browser': 'LoRAブラウザ',
    'search_lora': 'LoRAを検索...',
    'close': '閉じる',
    'no_lora': 'LoRAが見つかりません',
    'alias': 'エイリアス',

    // ライセンス
    'oss_licenses': 'オープンソースライセンス',
    'description': '説明',
    'version': 'バージョン',
    'links': 'リンク',
    'homepage': 'ホームページ',
    'repository': 'リポジトリ',
    'license': 'ライセンス',
    'no_license': 'ライセンス情報なし',

    // ヒントカード
    'hint_title': '使い方のヒント',
    'hint_chip_convert': 'カンマ区切りでチップに変換',
    'hint_edit_chip': 'チップをダブルタップで編集',
    'hint_weight': 'Shift + ホイールで重み調整',
    'hint_reorder': 'ドラッグ&ドロップで並び替え',
    'hint_lora': '<lora:name:weight> 形式でLoRAを追加',

    // システムモニター
    'cpu': 'CPU',
    'ram': 'RAM',
    'gpu': 'GPU',
    'vram': 'VRAM',
  };

  // ── English ──
  static const _en = {
    // Sidebar
    'settings_panel': 'Settings Panel',
    'system_monitor': 'System Monitor',
    'license_info': 'License Info',
    'language': 'Language',

    // Settings pane
    'settings': 'Settings',
    'detailed_settings': 'Detailed Settings',
    'api_settings': 'API Settings',
    'api_url': 'API URL',
    'ui_debug_mode': 'UI Debug Mode',
    'model_sampling': 'Model & Sampling',
    'model': 'Model',
    'select_model': 'Select model',
    'sampler': 'Sampler',
    'scheduler': 'Scheduler',
    'auto': 'Auto',
    'sampling_steps': 'Sampling Steps',
    'cfg_scale': 'CFG Scale',
    'image_settings': 'Image Settings',
    'width': 'Width',
    'height': 'Height',
    'batch_size': 'Batch Size',
    'batch_count': 'Batch Count',
    'seed': 'Seed',
    'seed_hint': '-1 (Random)',
    'extensions_others': 'Extensions & Others',
    'save_to_server': 'Save to Server',
    'browse_lora': 'Browse LoRA',
    'error': 'Error',
    'loading': 'Loading...',

    // Prompt
    'prompt': 'Prompt',
    'negative_prompt': 'Negative Prompt',
    'prompt_hint': 'Enter prompt... (separate with commas to create chips)',
    'negative_prompt_hint':
        'Enter negative prompt... (separate with commas to create chips)',
    'edit_chip': 'Edit Chip',
    'cancel': 'Cancel',
    'save': 'Save',
    'show_hints': 'Show hints',
    'weight': 'Weight',
    'clear_prompt': 'Clear Prompt',
    'clear': 'Clear',
    'select_all': 'Select All',
    'hint': 'Hint',
    'prompt_no_chips': 'No chips. Enter prompts in the field above.',
    'negative_prompt_no_chips':
        'No chips. Enter negative prompts in the field above.',
    'weight_range_helper': '0.1 ~ 5.0',
    'png_info_tab': 'PNG Info (D&D)',
    'detailed_settings_tooltip': 'Detailed Settings',

    // Preview
    'generation_preview': 'Generation Preview',
    'png_info': 'PNG Info',
    'fullscreen': 'Fullscreen',
    'close_image': 'Close image',
    'send_to_txt2img': 'Send to Txt2Img',
    'params_sent': 'Parameters sent to Txt2Img',
    'file_read_error': 'Error reading file',
    'generate': 'Generate',
    'interrupt': 'Interrupt',
    'no_image': 'No image generated yet',
    'tap_generate': 'Press "Generate" to create an image',
    'drag_drop_png': 'Drop a PNG file to view metadata',
    'drop_image_here': 'Drop an image here',

    // LoRA browser
    'lora_browser': 'LoRA Browser',
    'search_lora': 'Search LoRA...',
    'close': 'Close',
    'no_lora': 'No LoRA found',
    'alias': 'Alias',

    // License
    'oss_licenses': 'Open Source Licenses',
    'description': 'Description',
    'version': 'Version',
    'links': 'Links',
    'homepage': 'Homepage',
    'repository': 'Repository',
    'license': 'License',
    'no_license': 'No license information',

    // Hint card
    'hint_title': 'Tips',
    'hint_chip_convert': 'Separate with commas to create chips',
    'hint_edit_chip': 'Double-tap a chip to edit',
    'hint_weight': 'Shift + scroll to adjust weight',
    'hint_reorder': 'Drag & drop to reorder',
    'hint_lora': 'Add LoRA with <lora:name:weight> format',

    // System monitor
    'cpu': 'CPU',
    'ram': 'RAM',
    'gpu': 'GPU',
    'vram': 'VRAM',
  };
}
