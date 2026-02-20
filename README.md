# Forge Flutter Client

[![Version](https://img.shields.io/badge/version-v0.3.0--alpha-orange)](https://github.com/fal-114514/forge-flutter)
[![Platform](https://img.shields.io/badge/platform-Windows-blue)](https://github.com/fal-114514/forge-flutter)
[![License](https://img.shields.io/badge/license-zlib-green)](LICENSE)

**[日本語版 README はこちら](README.ja.md)**

<div align="center">
  <img src="docs/images/preview_main.png" width="100%" alt="Preview Main">
</div>

Forge Flutter Client is an ultra-lightweight desktop application for [Forge Classic Neo](https://github.com/Haoming02/sd-webui-forge-classic), designed to minimize memory consumption during image generation.

<details>
<summary>📸 <strong>Screenshot Gallery</strong> (Click to expand)</summary>

|                              Main UI                               |                                  Memory Usage                                  |
| :----------------------------------------------------------------: | :----------------------------------------------------------------------------: |
| <img src="docs/images/preview_main.png" width="800" alt="Main UI"> | <img src="docs/images/preview_taskmanager.png" width="800" alt="Memory Usage"> |

</details>

## Overview

- **Concept:** An ultra-lightweight desktop app for Forge Classic Neo
- **Goal:** Minimize memory usage to free up resources for generation
- **Performance:**
  - **Forge Flutter Client:** ~55 MB (Startup) / ~66 MB (Processing) / ~80 MB (Post-generation)
  - **Browser WebUI:** ~300 MB+ (Startup)

## Key Features

- **🚀 Ultra Lightweight:** Built with Flutter (Windows Native). Keeps memory footprint minimal compared to browser-based interfaces.
- **🏷️ Chip-based Prompt Editor:** Manage prompts visually as tags. Adjust weights easily, reorder by drag & drop.
- **🖼️ PNG Info Support:** Drag & drop images to parse generation metadata and apply it instantly.
- **📦 Portable:** No installation required. Just run `forge_flutter.exe`.

## Technical Stack

- **Framework:** Flutter (Windows Native)
- **UI Design:** [Forui](https://forui.dev/) (Minimalistic Flutter UI Library)
- **Fonts:**
  - **UI:** IBM Plex Sans JP
  - **Editor:** Geist Mono
- **License:** zlib License

## Motivation

Existing WebUI solutions (Gradio-based) are feature-rich but resource-heavy. Browsers consume significant RAM, which affects performance on lower-end machines. This project aims to provide a dedicated, snappy, and aesthetic native interface that stays out of the way.

## Quick Start

New to Forge Flutter Client? See the [Quick Start Guide](docs/QUICKSTART.md) for setup instructions.

> [!NOTE]
> Pre-built binaries are currently available for **Windows only**.
> Linux / macOS users will need to build from source.

## Contribution

This project is currently in **alpha**. Contributions are very welcome!

- Bug reports & Feature requests via Issues
- Pull Requests
- Documentation improvements

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.
