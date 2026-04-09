#!/bin/bash
# ============================================================
# md2pdf - Markdown to PDF Conversion Tool
# ============================================================
# A portable tool for converting Chinese/English Markdown files
# to well-formatted PDF documents using pandoc + XeLaTeX.
#
# Usage:
#   ./md2pdf.sh input.md [output.pdf] [--toc] [--lang zh|en] [--template default|minimal|report]
#
# Dependencies:
#   - pandoc (>= 2.9)
#   - texlive-xetex
#   - Chinese fonts: Noto Serif CJK SC, Noto Sans CJK SC
#
# Examples:
#   ./md2pdf.sh report.md                          # Basic conversion
#   ./md2pdf.sh report.md output.pdf --toc         # With table of contents
#   ./md2pdf.sh report.md --lang zh --template report  # Chinese report style
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
FILTERS_DIR="$SCRIPT_DIR/filters"

# ---- Defaults ----
INPUT=""
OUTPUT=""
TOC=false
LANG="zh"
TEMPLATE="default"
FONT_SIZE="11pt"
PAPER="a4paper"
MARGIN="2cm"
LINE_STRETCH="1.3"

# ---- Color output ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---- Usage ----
usage() {
    cat <<'EOF'
Usage: md2pdf.sh <input.md> [output.pdf] [options]

Options:
  --toc                  Generate table of contents
  --lang <zh|en>         Document language (default: zh)
  --template <name>      Template: default, minimal, report (default: default)
  --font-size <size>     Font size: 10pt, 11pt, 12pt (default: 11pt)
  --paper <size>         Paper: a4paper, letterpaper (default: a4paper)
  --margin <size>        Page margin (default: 2cm)
  --line-stretch <n>     Line spacing multiplier (default: 1.3)
  --preprocess           Run ASCII-art cleanup before conversion
  -h, --help             Show this help

Examples:
  ./md2pdf.sh report.md
  ./md2pdf.sh report.md output.pdf --toc --lang zh --template report
  ./md2pdf.sh report.md --preprocess --toc
EOF
    exit 0
}

# ---- Parse args ----
PREPROCESS=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)     usage ;;
        --toc)         TOC=true; shift ;;
        --lang)        LANG="$2"; shift 2 ;;
        --template)    TEMPLATE="$2"; shift 2 ;;
        --font-size)   FONT_SIZE="$2"; shift 2 ;;
        --paper)       PAPER="$2"; shift 2 ;;
        --margin)      MARGIN="$2"; shift 2 ;;
        --line-stretch) LINE_STRETCH="$2"; shift 2 ;;
        --preprocess)  PREPROCESS=true; shift ;;
        -*)            error "Unknown option: $1" ;;
        *)
            if [[ -z "$INPUT" ]]; then
                INPUT="$1"
            elif [[ -z "$OUTPUT" ]]; then
                OUTPUT="$1"
            else
                error "Unexpected argument: $1"
            fi
            shift ;;
    esac
done

[[ -z "$INPUT" ]] && error "No input file specified. Use -h for help."
[[ -f "$INPUT" ]] || error "Input file not found: $INPUT"

# Default output filename
if [[ -z "$OUTPUT" ]]; then
    OUTPUT="${INPUT%.md}.pdf"
fi

# ---- Check dependencies ----
check_deps() {
    command -v pandoc >/dev/null 2>&1 || error "pandoc not found. Install: sudo apt install pandoc"
    command -v xelatex >/dev/null 2>&1 || error "xelatex not found. Install: sudo apt install texlive-xetex"

    if [[ "$LANG" == "zh" ]]; then
        if ! fc-list | grep -q "Noto Serif CJK SC"; then
            warn "Noto Serif CJK SC font not found. Install: sudo apt install fonts-noto-cjk"
        fi
    fi
}

# ---- Preprocess: fix ASCII art for LaTeX ----
preprocess_md() {
    local src="$1"
    local tmp="${src%.md}_pdf_tmp.md"

    python3 "$SCRIPT_DIR/preprocess.py" "$src" "$tmp"
    echo "$tmp"
}

# ---- Select template YAML ----
get_template_yaml() {
    local tpl="$TEMPLATES_DIR/${TEMPLATE}.yaml"
    if [[ ! -f "$tpl" ]]; then
        warn "Template '$TEMPLATE' not found, falling back to 'default'"
        tpl="$TEMPLATES_DIR/default.yaml"
    fi
    echo "$tpl"
}

# ---- Run pandoc ----
run_pandoc() {
    local src="$1"
    local tpl_yaml
    tpl_yaml="$(get_template_yaml)"

    local cmd=(
        pandoc "$src" "$tpl_yaml"
        -o "$OUTPUT"
        --pdf-engine=xelatex
        --wrap=none
        -V "colorlinks=true"
        -V "fontsize=$FONT_SIZE"
        -V "geometry=$PAPER, margin=$MARGIN"
        -V "linestretch=$LINE_STRETCH"
    )

    # Table of contents
    if [[ "$TOC" == true ]]; then
        cmd+=(--toc --toc-depth=3)
    fi

    # Lua filter for table column widths
    local lua_filter="$FILTERS_DIR/table_wrap.lua"
    if [[ -f "$lua_filter" ]]; then
        cmd+=(--lua-filter="$lua_filter")
    fi

    # Execute directly (not via eval)
    "${cmd[@]}" 2>&1
}

# ---- Main ----
main() {
    check_deps

    info "Input:    $INPUT"
    info "Output:   $OUTPUT"
    info "Template: $TEMPLATE"
    info "Language: $LANG"

    local src="$INPUT"

    # Optional preprocessing
    if [[ "$PREPROCESS" == true ]]; then
        info "Preprocessing: cleaning ASCII art and formatting..."
        src="$(preprocess_md "$INPUT")"
        info "Preprocessed to: $src"
    fi

    # Run pandoc
    info "Running pandoc..."
    run_pandoc "$src"

    # Check result
    if [[ -f "$OUTPUT" ]]; then
        local pages size
        pages=$(pdfinfo "$OUTPUT" 2>/dev/null | grep "Pages:" | awk '{print $2}' || echo "?")
        size=$(du -h "$OUTPUT" | cut -f1)
        info "Success! Generated: $OUTPUT ($pages pages, $size)"
    else
        error "PDF generation failed."
    fi

    # Cleanup temp file
    if [[ "$PREPROCESS" == true && "$src" != "$INPUT" ]]; then
        rm -f "$src"
    fi
}

main
