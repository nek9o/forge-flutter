# Forge Flutter Client

[![Version](https://img.shields.io/badge/version-v0.1.0--alpha-orange)](https://github.com/fal-114514/forge-flutter)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

**[日本語版 README はこちら](README.ja.md)**

Forge Flutter Client is an ultra-lightweight desktop application for [SD-WebUI-Forge](https://github.com/lllyasviel/stable-diffusion-webui-forge), designed to minimize memory consumption during image generation.

## 1. Core Metadata

- **App Name:** Forge Flutter Client
- **Version:** v0.1.0-alpha
- **Concept:** An ultra-lightweight desktop app for SD-WebUI-Forge (minimizing memory usage)
- **Key Achievement:** ~55 MB memory at startup / ~80 MB during use (browser-based WebUI uses ~300 MB at startup alone)

## 2. Technical Stack

- **Framework:** Flutter (Windows Native)
- **UI Design:** Material 3 Expressive
- **Fonts:**
  - **Main UI:** IBM Plex Sans JP (balancing readability and modern aesthetics)
  - **Prompt Display:** Geist Mono (monospaced font for clear input visualization)
- **License:** MIT License
  - Note: Dependencies include `dbus` (MPL-2.0), but the application itself is released under the MIT License.

## 3. Key Features

- **Lightweight:** Eliminates the need for a browser (Edge/Chrome), minimizing VRAM and RAM contention.
- **Chip-based Prompt Editor:** Manage prompts visually as tags with intuitive weight adjustment.
- **PNG Info:** Drag & drop images to parse prompt metadata and apply it directly to generation settings.
- **Portable:** No installation required. Simply extract and run the EXE.

> [!NOTE]
> Pre-built binaries are currently available for **Windows only**.
> Linux / macOS users will need to build from source. See the [Quick Start Guide](docs/QUICKSTART.md) for instructions.

## 4. Motivation

Existing WebUI solutions (Gradio-based) are feature-rich, but the browser itself consumes significant memory, putting strain on low- to mid-spec PCs during image generation. This project was born from the desire for a dedicated, snappy, and well-designed tool that stays out of the way.

## 5. Quick Start

New to Forge Flutter Client? See the [Quick Start Guide](docs/QUICKSTART.md) for setup instructions with StabilityMatrix + Forge Neo via API.

## 6. Contribution

This project is currently in alpha. There are unimplemented features and known bugs.

Contributions are very welcome, including:

- Bug reports and feature requests via Issues
- Pull requests for improvements
- Corrections to Japanese/English wording

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.
