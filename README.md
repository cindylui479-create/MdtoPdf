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

### v1.0.1 (2026-04-09)

**Bug fixes:**

- **TOC alignment** — Replaced `titlesec` with `sectsty` in `report.yaml`. `titlesec` redefines section internals and caused `hyperref` anchor placement to land on the wrong page when a heading appeared at the top of a new page, breaking PDF bookmark/outline navigation. `sectsty` changes only fonts and colors, leaving section mechanics intact.
- **TOC dot leaders** — Added `tocloft` package with `\cftsecleader` / `\cftsubsecleader` / `\cftsubsubsecleader` dot leaders so all TOC levels align page numbers at the right margin.
- **TOC page numbers** — Rewrote `run_pandoc()` in `md2pdf.sh` to first generate `.tex` via pandoc, then compile with `xelatex` three times. Single-pass compilation produces incorrect TOC page numbers; three passes guarantee convergence.
- **Table cell overflow** — Added `xurl` (URL line-breaking), `ragged2e`, and `microtype` packages. `table_wrap.lua` now uses 94% of text width (`TOTAL_WIDTH = 0.94`) instead of 100% to prevent cell content from overflowing into page margins.
- **Code block margin overflow** — Added `fvextra` with `\fvset{breaklines=true, breakanywhere=true}` so all fenced code blocks auto-wrap long lines. `preprocess.py` now also reduces font size (`\small` / `\scriptsize`) for code blocks with very long lines.
- **Wide table font scaling** — `preprocess.py` adds `\small` before tables with more than 5 columns.
- **Horizontal rule removal** — `table_wrap.lua` now filters out `HorizontalRule` elements so `---` separators in Markdown do not render as visible lines in the PDF body.
- **Page overflow tolerance** — Added `\setlength{\emergencystretch}{3em}` and `\setlength{\hfuzz}{3pt}` to reduce overfull box errors in regular paragraphs.

### v1.0.0 (2026-04-08)
- Initial release
- Three templates: default, report, minimal
- Lua filter for table column width balancing
- Python preprocessor for ASCII art cleanup
- Chinese/English bilingual support
