# Forge Flutter Client

[![Version](https://img.shields.io/badge/version-v0.1.0--alpha-orange)](https://github.com/fal-114514/forge-flutter)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

**[English README](README.md)**

Forge Flutter Client は、[SD-WebUI-Forge](https://github.com/lllyasviel/stable-diffusion-webui-forge) 用の超軽量デスクトップアプリケーションです。画像生成時のメモリ消費を極限まで抑えることをコンセプトに開発されています。

## 1. 基本情報 (Core Metadata)

- **アプリ名:** Forge Flutter Client
- **バージョン:** v0.1.0-alpha
- **コンセプト:** SD-WebUI-Forge用の超軽量デスクトップアプリ（メモリ消費の極小化）
- **主要な成果:** リリースビルドでのメモリ使用量 約55MB（ブラウザ版の約1/8）

## 2. 技術スタック (Technical Stack)

- **フレームワーク:** Flutter (Windows Native)
- **UIデザイン:** Material 3 Expressive
- **使用フォント:**
  - **メインUI:** IBM Plex Sans JP（視認性とモダンさの両立）
  - **プロンプト表示:** Geist Mono（等幅フォントによる入力の明確化）
- **ライセンス:** MIT License
  - ※依存関係に `dbus` (MPL-2.0) を含みますが、本アプリ自体は MIT ライセンスで公開されています。

## 3. 主要機能 (Key Features)

- **軽量性:** ブラウザ（Edge/Chrome）を介さないため、VRAMやRAMの競合を最小限に抑制します。
- **チップ形式プロンプト:** プロンプトをタグのように視覚的に管理し、重み付けを直感的に操作可能です。
- **PNG Info機能:** 画像をドラッグ＆ドロップしてプロンプト情報を解析し、そのまま生成設定に反映できます。
- **ポータブル動作:** インストール不要。解凍したフォルダ内の EXE を実行するだけで動作します。

## 4. 開発の動機 (Motivation)

既存の WebUI（Gradioベース）は多機能ですが、ブラウザ自体のメモリ消費が激しく、低・中スペックPCでの画像生成時にリソースを圧迫していると感じたため開発を開始しました。
「道具」として、よりサクサク動き、かつ洗練されたデザインの専用環境を求めて構築しています。

## 5. コントリビューション方針 (Contribution)

本プロジェクトは現在アルファ版であり、未実装の機能やバグが存在します。

- Issue でのバグ報告や機能提案
- プルリクエストによる改善
- 日本語・英語の表現修正

などは大歓迎です。詳細は [CONTRIBUTING.md](CONTRIBUTING.md) をご確認ください。
