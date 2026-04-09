#!/usr/bin/env python3
"""
Markdown Preprocessor for PDF Conversion
=========================================
Cleans up Markdown content that doesn't render well in LaTeX/PDF:
  1. Converts ASCII-art box diagrams to structured tables or descriptions
  2. Converts ASCII flow diagrams (arrows) to LaTeX math-mode arrows
  3. Removes Markdown TOC links (pandoc generates its own)
  4. Fixes blockquote formatting for title areas

Usage:
    python3 preprocess.py input.md output.md
    python3 preprocess.py input.md          # prints to stdout
"""

import re
import sys


def remove_markdown_toc(content: str) -> str:
    """Remove manually written TOC sections (pandoc auto-generates).

    Handles both bullet-style (- [...]) and numbered-style (1. [...]) entries,
    with optional blank line between the heading and the first entry.
    """
    content = re.sub(
        r'^## (?:目录|Table of Contents)[ \t]*\n'  # section heading
        r'\n?'                                       # optional blank line
        r'(?:(?:\d+\.|-)[ ]\[.*?\]\(#.*?\)\n)+'    # one or more TOC entries
        r'\n?',                                      # optional trailing blank line
        '',
        content,
        flags=re.MULTILINE,
    )
    return content


def fix_title_blockquotes(content: str) -> str:
    """Convert leading blockquotes (used as subtitles) to bold text."""
    lines = content.split('\n')
    result = []
    in_header = True  # Only process blockquotes near the top

    for i, line in enumerate(lines):
        if in_header and line.startswith('> '):
            # Convert blockquote to bold paragraph
            text = line[2:].strip()
            result.append(f'**{text}**\n')
        else:
            if line.startswith('#'):
                in_header = False
            result.append(line)

    return '\n'.join(result)


def convert_ascii_boxes(content: str) -> str:
    """
    Detect ASCII box art in code blocks and convert to descriptive format.
    Targets patterns like:
        ```
        ┌──────────┐
        │ content   │
        └──────────┘
        ```
    """
    def has_box_chars(text):
        box_chars = set('┌┐└┘├┤┬┴─│╔╗╚╝║═╠╣╦╩')
        return any(c in box_chars for c in text)

    lines = content.split('\n')
    result = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Check if entering a code block with box characters
        if line.strip() == '```':
            # Collect code block content
            block_lines = []
            j = i + 1
            while j < len(lines) and lines[j].strip() != '```':
                block_lines.append(lines[j])
                j += 1

            block_text = '\n'.join(block_lines)

            if has_box_chars(block_text):
                # Extract text content from box art
                extracted = extract_box_content(block_lines)
                result.append('')
                for item in extracted:
                    result.append(item)
                result.append('')
                i = j + 1  # Skip past closing ```
            else:
                # Keep non-box code blocks as-is
                result.append(line)
                i += 1
        else:
            result.append(line)
            i += 1

    return '\n'.join(result)


def extract_box_content(lines: list) -> list:
    """Extract meaningful text from ASCII box art lines."""
    result = []
    for line in lines:
        # Remove box-drawing characters
        cleaned = line
        for ch in '┌┐└┘├┤┬┴─│╔╗╚╝║═╠╣╦╩':
            cleaned = cleaned.replace(ch, ' ')
        cleaned = cleaned.strip()
        if cleaned:
            # Format as a descriptive list item or bold text
            if ':' in cleaned or '(' in cleaned:
                result.append(f'- {cleaned}')
            else:
                result.append(f'**{cleaned}**')
    return result


def convert_inline_arrows(content: str) -> str:
    """
    Convert text arrows in code blocks to LaTeX math arrows for PDF.
    Only processes single-line code blocks that look like flow diagrams.
    """
    lines = content.split('\n')
    result = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Single-line code block with arrows (flow diagram)
        if line.strip() == '```':
            # Check if it's a single-line code block
            if i + 2 < len(lines) and lines[i + 2].strip() == '```':
                inner = lines[i + 1]
                if '→' in inner or '←' in inner or '↓' in inner:
                    # Convert to bold text with LaTeX arrows
                    converted = inner.strip()
                    converted = converted.replace('→', '$\\rightarrow$')
                    converted = converted.replace('←', '$\\leftarrow$')
                    converted = converted.replace('↓', '$\\downarrow$')
                    converted = converted.replace('~~', '')
                    result.append('')
                    result.append(f'**{converted}**')
                    result.append('')
                    i += 3
                    continue

        result.append(line)
        i += 1

    return '\n'.join(result)


def fix_code_block_overflow(content: str) -> str:
    """
    Prevent code blocks from overflowing the page margin.

    Strategy:
    1. Code blocks whose longest line exceeds LONG_LINE_CHARS are wrapped in a
       LaTeX ``\\small`` directive so the monospace font is slightly smaller,
       buying ~15% extra line capacity without breaking the verbatim environment.
    2. Code blocks whose longest line exceeds WRAP_LINE_CHARS get an additional
       ``\\scriptsize`` to push even the most extreme cases inside the margin.

    These font-size overrides work because pandoc emits code blocks as
    ``\\begin{Shaded}...\\end{Shaded}`` (fancyvrb), and raw LaTeX commands
    placed *before* the opening fence are respected by XeLaTeX.
    The ``\\fvset{breaklines=true}`` in report.yaml handles the actual line
    breaking; \\small / \\scriptsize reduce the need for it on very long lines.
    """
    LONG_LINE_CHARS = 72   # lines longer than this trigger \small
    WRAP_LINE_CHARS = 100  # lines longer than this trigger \scriptsize

    lines = content.split('\n')
    result = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Detect opening fence: ``` or ```lang
        if re.match(r'^```', line.strip()):
            fence_indent = len(line) - len(line.lstrip())
            block = [line]
            max_len = 0
            j = i + 1

            # Collect until closing fence
            while j < len(lines):
                block.append(lines[j])
                stripped = lines[j].strip()
                if stripped == '```' and j > i:
                    break
                max_len = max(max_len, len(lines[j]))
                j += 1

            # Choose font size override based on longest line
            if max_len > WRAP_LINE_CHARS:
                result.append('\\scriptsize')
                result.extend(block)
                result.append('\\normalsize')
            elif max_len > LONG_LINE_CHARS:
                result.append('\\small')
                result.extend(block)
                result.append('\\normalsize')
            else:
                result.extend(block)

            i = j + 1
        else:
            result.append(line)
            i += 1

    return '\n'.join(result)


def fix_wide_tables(content: str) -> str:
    """
    Add LaTeX small font directive before tables with many columns (>5).
    This helps wide tables fit on the page.
    """
    lines = content.split('\n')
    result = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Detect table header (pipe-delimited)
        if '|' in line and i + 1 < len(lines) and re.match(r'^\|[-:| ]+\|$', lines[i + 1].strip()):
            col_count = line.count('|') - 1
            if col_count > 5:
                # Insert LaTeX font size command before wide tables
                result.append('')
                result.append('\\small')
                result.append('')

            result.append(line)
            i += 1

            # After the table ends, restore normal size
            while i < len(lines) and '|' in lines[i]:
                result.append(lines[i])
                i += 1

            if col_count > 5:
                result.append('')
                result.append('\\normalsize')
                result.append('')
        else:
            result.append(line)
            i += 1

    return '\n'.join(result)


def preprocess(content: str) -> str:
    """Run all preprocessing steps."""
    content = remove_markdown_toc(content)
    content = fix_title_blockquotes(content)
    content = convert_ascii_boxes(content)
    content = convert_inline_arrows(content)
    content = fix_code_block_overflow(content)   # v1.0.1: shrink wide code blocks
    content = fix_wide_tables(content)
    return content


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None

    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    result = preprocess(content)

    if output_file:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(result)
    else:
        print(result)


if __name__ == '__main__':
    main()
