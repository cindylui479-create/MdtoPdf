# MdtoPdf - Markdown to PDF Conversion Tool

A portable, configurable tool for converting Markdown files to well-formatted PDF documents. Optimized for Chinese/English content with proper table rendering, headers/footers, and professional typography.

## Features

- Chinese/English bilingual support (Noto CJK fonts)
- Multiple templates: `default`, `report` (with TOC + styled headers), `minimal`
- Auto table column width balancing (Lua filter)
- Optional preprocessing: ASCII art cleanup, wide table font scaling
- Clickable hyperlinks and colored section headers
- Page headers/footers with page numbers

## Quick Start

```bash
# Basic conversion
./md2pdf.sh my-document.md

# Report style with table of contents
./md2pdf.sh my-document.md --template report --toc

# With preprocessing (fixes ASCII diagrams)
./md2pdf.sh my-document.md output.pdf --preprocess --template report
```

## Installation

### Dependencies

```bash
# Ubuntu/Debian
sudo apt install pandoc texlive-xetex fonts-noto-cjk poppler-utils

# macOS (Homebrew)
brew install pandoc
brew install --cask mactex
# Download Noto CJK fonts from https://github.com/notofonts/noto-cjk
```

### Setup

```bash
chmod +x md2pdf.sh
```

## Usage

```
./md2pdf.sh <input.md> [output.pdf] [options]

Options:
  --toc                  Generate table of contents
  --lang <zh|en>         Document language (default: zh)
  --template <name>      Template: default, minimal, report
  --font-size <size>     Font size: 10pt, 11pt, 12pt (default: 11pt)
  --paper <size>         Paper: a4paper, letterpaper (default: a4paper)
  --margin <size>        Page margin (default: 2cm)
  --line-stretch <n>     Line spacing (default: 1.3)
  --preprocess           Clean ASCII art before conversion
  -h, --help             Show help
```

## Directory Structure

```
MdtoPdf/
├── md2pdf.sh            # Main conversion script
├── preprocess.py        # Markdown preprocessor (ASCII art, tables)
├── templates/
│   ├── default.yaml     # Clean, simple style
│   ├── report.yaml      # Professional report with TOC + headers
│   └── minimal.yaml     # Bare minimum formatting
├── filters/
│   └── table_wrap.lua   # Pandoc Lua filter for table column widths
└── README.md
```

## Templates

### `default`
Clean document style. No TOC, simple page numbering, colored links.

### `report`
Professional report style:
- Auto-generated Table of Contents
- Blue section headers
- Page header with section name
- Styled page footer

### `minimal`
Bare-bones formatting. No headers/footers, minimal packages.

## Customization

### Adding a new template

1. Copy an existing `.yaml` file in `templates/`
2. Modify fonts, colors, spacing, LaTeX packages as needed
3. Use via `--template your-template-name`

### Key LaTeX variables you can customize in YAML:

| Variable | Description | Example |
|----------|-------------|---------|
| `CJKmainfont` | Chinese body font | `"Noto Serif CJK SC"` |
| `mainfont` | Latin body font | `"Noto Serif CJK SC"` |
| `monofont` | Code font | `"DejaVu Sans Mono"` |
| `geometry` | Page layout | `"a4paper, margin=2cm"` |
| `fontsize` | Base font size | `"11pt"` |
| `linestretch` | Line spacing | `1.3` |
| `toc` | Table of contents | `true` / `false` |

### Preprocessor

The `preprocess.py` script handles Markdown patterns that LaTeX renders poorly:

- **ASCII box art** (e.g., `┌──┐`) → structured list items
- **Single-line flow diagrams** (`A → B → C`) → LaTeX math arrows
- **Wide tables** (>5 columns) → auto font-size reduction
- **Manual TOC** → removed (pandoc generates its own)

## Changelog

### v1.0.0 (2026-04-08)
- Initial release
- Three templates: default, report, minimal
- Lua filter for table column width balancing
- Python preprocessor for ASCII art cleanup
- Chinese/English bilingual support
