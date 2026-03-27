# Forge Flutter Client

[![Version](https://img.shields.io/badge/version-v2026.3.27--1)](https://github.com/fal-114514/forge-flutter)
[![Platform](https://img.shields.io/badge/platform-Windows-blue)](https://github.com/fal-114514/forge-flutter)
[![License](https://img.shields.io/badge/license-Blue%20Oak%201.0.0-blue)](LICENSE.md)

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
- **License:** Blue Oak Model License 1.0.0

## Motivation

Existing WebUI solutions (Gradio-based) are feature-rich but resource-heavy. Browsers consume significant RAM, which affects performance on lower-end machines. This project aims to provide a dedicated, snappy, and aesthetic native interface that stays out of the way.

## Quick Start

New to Forge Flutter Client? See the [Quick Start Guide](docs/QUICKSTART.md) for setup instructions.

> [!NOTE]
> Pre-built binaries are currently available for **Windows only**.
> Linux / macOS users will need to build from source.

## Contribution

This project is currently in active development. Please note that **all 0.x versions are considered development versions**, and major changes may occur. Contributions are very welcome!

- Bug reports & Feature requests via Issues
- Pull Requests
- Documentation improvements

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Disclaimer

> [!CAUTION]
>
> - **Disclaimer of Warranty**: This software is provided "as-is" without warranty of any kind. The creator makes no warranties, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement of third-party intellectual property rights.
> - **Limitation of Liability**: In no event shall the creator be liable for any damages, losses, or issues (including direct or indirect) arising from the use of this software (including installation, customization, and publication), to the maximum extent permitted by law.
> - **AI Usage Disclosure**: Parts of this software (code and design) have been created with the assistance of Generative AI technologies. Therefore, the creator cannot fully guarantee that such content does not infringe upon the intellectual property rights of third parties.
> - **Legal Interpretation**: The creator is not a legal expert and cannot provide definitive legal interpretations of this agreement or OSS licenses. If you have any concerns, please consult a legal professional at your own responsibility.
> - **Self-Responsibility**: All actions related to the use of this software are to be performed at the user's own risk and discretion.
